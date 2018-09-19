require 'fog/vcloud_director/generators/compute/compose_common'

module Fog
  module VcloudDirector
    module Generators
      module Compute
        class ReconfigureVm
          extend ComposeCommon

          NETWORK_SECTION_ORDER = ['ovf:Info'] + %w(PrimaryNetworkConnectionIndex NetworkConnection Link)
          NETWORK_CONNECTION_ORDER = %w(NetworkConnectionIndex IpAddress ExternalIpAddress IsConnected MACAddress IpAddressAllocationMode NetworkAdapterType).freeze

          class << self
            # Generates VM reconfiguration XML.
            #
            # @param [Nokogiri::Xml] current DOM representing current VM configuration.
            # @param [Hash] options desired configuration. Please see examples-vm-reconfigure.md for details.
            #
            # @return [String] xml string, a modification of `current` input, with desired configurations applied.
            def generate_xml(current, options)
              current.root['name'] = options[:name] if options[:name]
              current.at('Description').content = options[:description] if options[:description]
              # Remove entire section when no moification is required to improve performance, see
              # https://pubs.vmware.com/vcd-80/index.jsp#com.vmware.vcloud.api.sp.doc_90/GUID-4759B018-86C2-4C91-8176-3EC73CD7122B.html
              options[:hardware] ? update_virtual_hardware_section(current, options[:hardware]) : current.at('//ovf:VirtualHardwareSection').remove
              options[:networks] ? update_network_connection_section(current, options[:networks]) : current.at('//xmlns:NetworkConnectionSection').remove
              current.at('//ovf:OperatingSystemSection').remove # TODO(miha-plesko): support this type of customization
              current.at('//xmlns:GuestCustomizationSection').remove # TODO(miha-plesko): support this type of customization

              current.to_xml
            end

            # Apply desired hardware modifications to the original xml.
            def update_virtual_hardware_section(xml, hardware)
              update_virtual_hardware_section_item_mem(xml, **hardware[:memory]) if hardware[:memory]
              update_virtual_hardware_section_item_cpu(xml, **hardware[:cpu]) if hardware[:cpu]
              array_wrap(hardware[:disk]).reject { |d| d[:id].nil? || d[:capacity_mb] == -1 }.each { |disk| update_virtual_hardware_section_item_hdd(xml, **disk) }
              array_wrap(hardware[:disk]).select { |d| d[:id].nil? }.each { |disk| add_virtual_hardware_section_item_hdd(xml, **disk) }
              array_wrap(hardware[:disk]).select { |d| d[:capacity_mb] == -1 }.each { |disk| remove_virtual_hardware_section_item_hdd(xml, id: disk[:id]) }
            end

            # Apply desired NIC connection modifications to the original xml.
            def update_network_connection_section(xml, networks)
              array_wrap(networks).reject { |n| n[:new_idx] == -1 || n[:idx].nil? }.each { |nic| update_network_connection_section_by_index(xml, **nic) }
              array_wrap(networks).select { |n| n[:new_idx] == -1 }.each { |nic| remove_network_connection_section_by_index(xml, :idx => nic[:idx]) }
              array_wrap(networks).select { |n| n[:idx].nil? }.each { |nic| add_network_connection_section(xml, **nic) }
            end

            def update_virtual_hardware_section_item_cpu(xml, num_cores: nil, cores_per_socket: nil, reservation: nil, limit: nil, weight: nil)
              update_virtual_hardware_section_item(xml, :type => 3) do |item|
                item.at('./rasd:VirtualQuantity').content = num_cores if num_cores
                item.at('./rasd:Reservation').content = reservation if reservation
                item.at('./rasd:Limit').content = limit if limit
                item.at('./rasd:Weight').content = weight if weight
                item.at('./vmw:CoresPerSocket').content = cores_per_socket if cores_per_socket
              end
            end

            def update_virtual_hardware_section_item_mem(xml, quantity_mb: nil, reservation: nil, limit: nil, weight: nil)
              update_virtual_hardware_section_item(xml, :type => 4) do |item|
                item.at('./rasd:VirtualQuantity').content = quantity_mb if quantity_mb
                item.at('./rasd:Reservation').content = reservation if reservation
                item.at('./rasd:Limit').content = limit if limit
                item.at('./rasd:Weight').content = weight if weight
              end
            end

            def update_virtual_hardware_section_item_hdd(xml, id:, capacity_mb: nil, address: nil, type: nil, subtype: nil)
              hdd_exists = update_virtual_hardware_section_item(xml, :type => 17, :id => id) do |item|
                item.at('./rasd:AddressOnParent').content = address if address
                item.at('./rasd:HostResource')['ns13:capacity'] = capacity_mb if capacity_mb
                item.at('./rasd:HostResource')['ns13:busType'] = type if type
                item.at('./rasd:HostResource')['ns13:busSubType'] = subtype if subtype
              end
              raise Fog::VcloudDirector::Compute::PreProcessingError.new("Error resizing disk: disk with id '#{id}' does not exist.") unless hdd_exists
            end

            def remove_virtual_hardware_section_item_hdd(xml, id:)
              remove_virtual_hardware_section_item(xml, :type => 17, :id => id)
            end

            def add_virtual_hardware_section_item_hdd(xml, **disk)
              disk[:id] = rand(10_000..100_000)
              add_virtual_hardware_section_item(xml) do |section|
                virtual_hardware_section_item_hdd(section, **disk)
              end
            end

            def add_virtual_hardware_section_item(xml)
              virtual_hardware = xml.at('//ovf:VirtualHardwareSection')
              virtual_hardware.add_namespace_definition('vcloud', 'http://www.vmware.com/vcloud/v1.5')
              Nokogiri::XML::Builder.with(virtual_hardware) do |section|
                yield section
              end
              # Move the new item to satisfy vCloud's sorting requirements.
              item = virtual_hardware.at('./ovf:Item[last()]').remove
              virtual_hardware.at('./ovf:Item[last()]').after(item)
            end

            def update_virtual_hardware_section_item(xml, type:, id: nil)
              condition = "rasd:ResourceType = '#{type}'"
              condition += " and rasd:InstanceID = '#{id}'" if id
              if (item = xml.at("//ovf:VirtualHardwareSection/ovf:Item[#{condition}]"))
                yield item
                true
              else
                false
              end
            end

            def remove_virtual_hardware_section_item(xml, type:, id:)
              item = xml.at("//ovf:VirtualHardwareSection/ovf:Item[rasd:ResourceType = '#{type}' and rasd:InstanceID = '#{id}']")
              item.remove if item
            end

            def update_network_connection_section_by_index(xml, idx:, name: nil, mac: nil, ip: nil, connected: nil, mode: nil, type: nil, needs: nil, new_idx: nil, primary: nil)
              conn = xml.at("//xmlns:NetworkConnectionSection/xmlns:NetworkConnection[./xmlns:NetworkConnectionIndex = '#{idx}']")
              conn['network'] = name if name
              conn['needsCustomization'] = needs unless needs.nil?
              leaf_at(conn, 'IpAddress', NETWORK_CONNECTION_ORDER).content = ip unless ip.nil?
              leaf_at(conn, 'IpAddressAllocationMode', NETWORK_CONNECTION_ORDER).content = mode if mode
              leaf_at(conn, 'IsConnected', NETWORK_CONNECTION_ORDER).content = connected unless connected.nil?
              leaf_at(conn, 'MACAddress', NETWORK_CONNECTION_ORDER).content = mac if mac
              leaf_at(conn, 'NetworkAdapterType', NETWORK_CONNECTION_ORDER).content = type if type
              leaf_at(conn, 'NetworkConnectionIndex', NETWORK_CONNECTION_ORDER).content = new_idx if new_idx

              set_primary_nic(xml, new_idx || idx) if primary
            end

            def remove_network_connection_section_by_index(xml, idx:)
              conn = xml.at("//xmlns:NetworkConnectionSection/xmlns:NetworkConnection[./xmlns:NetworkConnectionIndex = '#{idx}']")
              conn.remove if conn
            end

            def add_network_connection_section(xml, primary: nil, **nic)
              nic.delete(:idx)
              network_section = xml.at('//xmlns:NetworkConnectionSection')
              network_section.add_namespace_definition('vcloud', 'http://www.vmware.com/vcloud/v1.5')
              Nokogiri::XML::Builder.with(network_section) do |section|
                network_section_nic(section, **nic)
              end

              # Move the new item to satisfy vCloud's sorting requirements.
              item = network_section.at('./xmlns:NetworkConnection[last()]').remove
              (previous = find_previous(network_section, 'NetworkConnection', NETWORK_SECTION_ORDER)) ? previous.after(item) : network_section.prepend_child(item)

              set_primary_nic(xml, nic[:new_idx]) if primary
            end

            def set_primary_nic(xml, idx)
              leaf_at(xml.at('//xmlns:NetworkConnectionSection'), 'PrimaryNetworkConnectionIndex', NETWORK_SECTION_ORDER).content = idx
            end

            # Find leaf element if present or create new one. Respect XML ordering when adding new.
            # Arguments:
            # - xml: parent xml whose child element are we updating/adding
            # - leaf_name: child element name (without namespace)
            # - order: list of child names in proper order
            # - ns: leaf element's namespace
            # Returns:
            # - leaf element
            def leaf_at(xml, leaf_name, order, ns: 'xmlns')
              el = xml.at("./#{ns}:#{leaf_name}")
              el || begin
                el = Nokogiri::XML::Node.new(ns == 'xmlns' ? leaf_name : "#{ns}:#{leaf_name}", xml)
                (previous = find_previous(xml, leaf_name, order)) ? previous.after(el) : xml.prepend_child(el)
                el
              end
            end

            # Finds previous sybling for a leaf_name in accordance with ordered list of child elements.
            # Arguments:
            # - xml: parent xml whose children are we checking
            # - leaf_name: child element name that we want to find preceeding sybling for (without namespace)
            # - order: list of child names in proper order
            # Returns:
            # - previous sybling element if found or nil
            def find_previous(xml, leaf_name, order)
              order.reduce(nil) do |res, curr_name|
                break res if curr_name == leaf_name
                xml.at(curr_name.include?(':') ? "./#{curr_name}" : "./xmlns:#{curr_name}") || res
              end
            end
          end
        end
      end
    end
  end
end
