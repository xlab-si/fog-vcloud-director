module Fog
  module VcloudDirector
    module Generators
      module Compute
        module ComposeCommon

          def initialize(configuration={})
            @configuration = configuration
          end

          private

          def href(path)
            @endpoint ||= @configuration[:endpoint].to_s.sub(/\/$/, '') # ensure not ending with '/'
            "#{@endpoint}#{path}"
          end

          def vapp_attrs
            attrs = {
              :xmlns          => 'http://www.vmware.com/vcloud/v1.5',
              'xmlns:vcloud'  => 'http://www.vmware.com/vcloud/v1.5',
              'xmlns:ovf'     => 'http://schemas.dmtf.org/ovf/envelope/1',
              'xmlns:vssd'    => 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData',
              'xmlns:rasd'    => 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData',
              'xmlns:vmw'     => 'http://www.vmware.com/schema/ovf'
            }

            [:deploy, :powerOn, :name].each do |a|
              attrs[a] = @configuration[a] if @configuration.key?(a)
            end
            
            attrs
          end

          def has_source_items?
            (@configuration[:source_vms] && (@configuration[:source_vms].size > 0)) || 
            (@configuration[:source_templates] && (@configuration[:source_templates].size > 0))
          end

          def build_vapp_instantiation_params(xml)
            xml.Description @configuration[:Description] if @configuration[:Description]
            return unless @configuration[:vapp_networks] || @configuration[:InstantiationParams]

            xml.InstantiationParams do
              if (vapp_networks = @configuration[:vapp_networks])
                xml.NetworkConfigSection do
                  xml['ovf'].Info
                  array_wrap(vapp_networks).each { |vapp_net| vapp_network_section(xml, **vapp_net) }
                end
              # Backwards compatibility
              # TODO: disable inputing InstantiationParams directly as below because it offers bad UX
              elsif (vapp = @configuration[:InstantiationParams])
                xml.DefaultStorageProfileSection {
                  xml.StorageProfile vapp[:DefaultStorageProfile]
                } if (vapp.key? :DefaultStorageProfile)
                xml.NetworkConfigSection {
                  xml['ovf'].Info
                  vapp[:NetworkConfig].each do |network|
                    xml.NetworkConfig(:networkName => network[:networkName]) {
                      xml.Configuration {
                        xml.ParentNetwork(:href => network[:networkHref])
                        xml.FenceMode network[:fenceMode]
                      }
                    }
                  end if vapp[:NetworkConfig]
                }
              end
            end
          end
          
          def build_source_template(xml)
            xml.Source(:href => @configuration[:Source])
          end

          def build_source_items(xml)
            vms = @configuration[:source_vms]
            vms.each do |vm|
              xml.SourcedItem {
                xml.Source(:name =>vm[:name], :href => vm[:href])
                xml.VmGeneralParams {
                  xml.Name vm[:name]
                  xml.Description vm[:Description] if vm[:Description]
                  xml.NeedsCustomization if vm[:NeedsCustomization]
                } if vm[:name]
                xml.InstantiationParams {
                  if vm[:networks]
                    xml.NetworkConnectionSection(:href => "#{vm[:href]}/networkConnectionSection/", :type => "application/vnd.vmware.vcloud.networkConnectionSection+xml", 'xmlns:ovf' => "http://schemas.dmtf.org/ovf/envelope/1", "ovf:required" => "false") {
                      xml['ovf'].Info
                      xml.PrimaryNetworkConnectionIndex 0
                      vm[:networks].each_with_index do |network, i|
                        xml.NetworkConnection(:network => network[:networkName]) {
                          xml.NetworkConnectionIndex i
                          xml.IpAddress network[:IpAddress] if (network.key? :IpAddress)
                          xml.ExternalIpAddress network[:ExternalIpAddress] if (network.key? :ExternalIpAddress)
                          xml.IsConnected network[:IsConnected]
                          xml.MACAddress network[:MACAddress] if (network.key? :MACAddress)
                          xml.IpAddressAllocationMode network[:IpAddressAllocationMode]
                        }
                      end
                    }
                  end
                  if customization = vm[:guest_customization]
                    xml.GuestCustomizationSection(:xmlns => "http://www.vmware.com/vcloud/v1.5", 'xmlns:ovf' => "http://schemas.dmtf.org/ovf/envelope/1") {
                      xml['ovf'].Info
                      xml.Enabled (customization[:Enabled] || false)
                      xml.ChangeSid customization[:ChangeSid] if (customization.key? :ChangeSid)
                      xml.JoinDomainEnabled customization[:JoinDomainEnabled] if (customization.key? :JoinDomainEnabled)
                      xml.UseOrgSettings customization[:UseOrgSettings] if (customization.key? :UseOrgSettings)
                      xml.DomainName customization[:DomainName] if (customization.key? :DomainName)
                      xml.DomainUserName customization[:DomainUserName] if (customization.key? :DomainUserName)
                      xml.DomainUserPassword customization[:DomainUserPassword] if (customization.key? :DomainUserPassword)
                      xml.MachineObjectOU customization[:MachineObjectOU] if (customization.key? :MachineObjectOU)
                      xml.AdminPasswordEnabled customization[:AdminPasswordEnabled] if (customization.key? :AdminPasswordEnabled)
                      xml.AdminPasswordAuto customization[:AdminPasswordAuto] if (customization.key? :AdminPasswordAuto)
                      xml.AdminPassword customization[:AdminPassword] if (customization.key? :AdminPassword)
                      xml.ResetPasswordRequired customization[:ResetPasswordRequired] if (customization.key? :ResetPasswordRequired)
                      xml.CustomizationScript CGI::escapeHTML(customization[:CustomizationScript]).gsub(/\r/, "&#13;") if (customization.key? :CustomizationScript)
                      xml.ComputerName customization[:ComputerName]
                    }
                  end
                  if (hardware = vm[:hardware])
                    build_virtual_hardware_section(xml, hardware)
                  end
                }
                xml.StorageProfile(:href => vm[:StorageProfileHref]) if (vm.key? :StorageProfileHref)
              }
            end if vms

            templates = @configuration[:source_templates]
            templates.each do |template|
              xml.SourcedItem { xml.Source(:href => template[:href]) }
            end if templates

            xml.AllEULAsAccepted (@configuration[:AllEULAsAccepted] || true)
          end

          def build_virtual_hardware_section(xml, hardware)
            xml[:ovf].VirtualHardwareSection do
              xml[:ovf].Info('Virtual hardware requirements')
              virtual_hardware_section_item_mem(xml, **hardware[:memory]) if hardware[:memory]
              virtual_hardware_section_item_cpu(xml, **hardware[:cpu]) if hardware[:cpu]
              array_wrap(hardware[:disk]).each { |disk| virtual_hardware_section_item_hdd(xml, **disk) }
            end
          end

          def virtual_hardware_section_item_base(xml, type:, name: nil, id: nil)
            id ||= SecureRandom.uuid
            name ||= id
            xml[:ovf].Item do
              xml[:rasd].ResourceType(type)
              xml[:rasd].ElementName(name)
              xml[:rasd].InstanceID(id)

              yield

              # RASD elements must be alphabetically sorted
              sort_nodes_by_name(xml)
            end
          end

          def virtual_hardware_section_item_mem(xml, quantity_mb:, reservation: nil, limit: nil, weight: nil)
            virtual_hardware_section_item_base(xml, :type => 4) do
              xml[:rasd].AllocationUnits('byte * 2^20')
              xml[:rasd].VirtualQuantity(quantity_mb)
              xml[:rasd].Reservation(reservation) if reservation
              xml[:rasd].Limit(limit) if limit
              xml[:rasd].Weight(weight) if weight
            end
          end

          def virtual_hardware_section_item_cpu(xml, num_cores:, cores_per_socket: nil, reservation: nil, limit: nil, weight: nil)
            virtual_hardware_section_item_base(xml, :type => 3) do
              xml[:rasd].AllocationUnits('hertz * 10^6')
              xml[:rasd].VirtualQuantity(num_cores)
              xml[:rasd].Reservation(reservation) if reservation
              xml[:rasd].Limit(limit) if limit
              xml[:rasd].Weight(weight) if weight
              xml[:vmw].CoresPerSocket(cores_per_socket) if cores_per_socket
            end
          end

          def virtual_hardware_section_item_hdd(xml, capacity_mb:, id:, address: nil, type: nil, subtype: nil)
            virtual_hardware_section_item_base(xml, :type => 17, :id => id) do
              xml[:rasd].AddressOnParent(address) if address
              attrs = {}
              attrs['vcloud:capacity'] = capacity_mb if capacity_mb
              attrs['vcloud:busType'] = type if type
              attrs['vcloud:busSubType'] = subtype if subtype
              xml[:rasd].HostResource(attrs)
            end
          end

          def sort_nodes_by_name(xml)
            nodes = xml.parent.children.remove
            nodes.sort_by { |n| "#{n.namespace.prefix}:#{n.name}" }.each { |n| xml.parent.add_child(n) }
          end

          def array_wrap(val)
            return val if val.kind_of?(Array)
            [val].compact
          end

          def vapp_network_section(xml, name:, subnet:, description: nil, deployed: nil, parent: nil, parent_name: nil,
                                   fence_mode: nil, retain: false, external_ip: nil)
            description ||= name
            parent = href("/network/#{parent}") if parent
            fence_mode = calculate_fence_mode(fence_mode, parent, parent_name)
            xml.NetworkConfig(:networkName => name) do
              xml.Description(description)
              xml.IsDeployed(deployed) unless deployed.nil?
              xml.Configuration do
                xml.IpScopes do
                  array_wrap(subnet).each { |s| ip_scope_section(xml, **s) }
                end
                attr = {
                  :href => parent.to_s
                }
                attr[:name] = parent_name if parent_name
                xml.ParentNetwork(attr) if parent || parent_name
                xml.FenceMode(fence_mode)
                xml.RetainNetInfoAcrossDeployments(retain)
                xml.RouterInfo do
                  xml.ExternalIp(external_ip)
                end if external_ip
              end
            end
          end

          def ip_scope_section(xml, gateway:, netmask:, enabled: true, inherited: false, dns1: nil, dns2: nil, dns_suffix: nil, ip_range: nil)
            xml.IpScope do
              xml.IsInherited(inherited)
              xml.Gateway(gateway)
              xml.Netmask(netmask)
              xml.Dns1(dns1) if dns1
              xml.Dns2(dns2) if dns2
              xml.DnsSuffix(dns_suffix) if dns_suffix
              xml.IsEnabled(enabled)
              xml.IpRanges do
                array_wrap(ip_range).each do |range|
                  xml.IpRange do
                    xml.StartAddress(range[:start])
                    xml.EndAddress(range[:end])
                  end
                end
              end if ip_range
            end
          end

          def calculate_fence_mode(mode, parent, parent_name)
            return 'isolated' unless parent || parent_name
            return 'bridged' unless mode && mode != 'isolated'
            mode
          end

          def network_section_nic(xml, new_idx:, name: 'none', mac: nil, ip: nil, connected: true, mode: 'DHCP', type: nil, needs: nil)
            attr = { :network => name }
            attr[:needsCustomization] = needs unless needs.nil?
            xml.NetworkConnection(attr) do
              xml.NetworkConnectionIndex(new_idx) if new_idx
              xml.IpAddress(ip) unless ip.nil?
              xml.IsConnected(connected) unless connected.nil?
              xml.MACAddress(mac) if mac
              xml.IpAddressAllocationMode(mode) if mode
              xml.NetworkAdapterType(type) if type
            end
          end
        end
      end
    end
  end
end
