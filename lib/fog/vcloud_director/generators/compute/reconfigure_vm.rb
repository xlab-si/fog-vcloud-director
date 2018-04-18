require 'fog/vcloud_director/generators/compute/compose_common'

module Fog
  module Generators
    module Compute
      module VcloudDirector
        class ReconfigureVm
          extend ComposeCommon

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
              if options[:hardware]
                update_virtual_hardware_section(current, options[:hardware])
              else
                # Remove entire VirtualHardwareSection if no hardware is modified.
                # https://pubs.vmware.com/vcd-80/index.jsp#com.vmware.vcloud.api.sp.doc_90/GUID-4759B018-86C2-4C91-8176-3EC73CD7122B.html
                current.at('//ovf:VirtualHardwareSection').remove
              end
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
              raise Fog::Compute::VcloudDirector::PreProcessingError.new("Error resizing disk: disk with id '#{id}' does not exist.") unless hdd_exists
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
          end
        end
      end
    end
  end
end
