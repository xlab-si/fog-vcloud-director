module Fog
  module Parsers
    module Compute
      module VcloudDirector
        module VmParserHelper
          def initialize_vm
            {
              :vapp_id     => nil,
              :ip_address  => '',
              :description => '',
            }
          end

          def parse_end_element(name, vm)
            case name
            when 'IpAddress'
              vm[:ip_address] = value
            when 'Description'
              if @in_operating_system
                vm[:operating_system] = value
                @in_operating_system = false
              end
            when 'ResourceType'
              @resource_type = value
            when 'VirtualQuantity'
              case @resource_type
              when '3'
                vm[:cpu] = value
              when '4'
                vm[:memory] = value
              end
            when 'ElementName'
              @element_name = value
            when 'Item'
              if @resource_type == '17' # disk
                vm[:disks] ||= []
                vm[:disks] << { @element_name => @current_host_resource[:capacity].to_i }
              end
            when 'Connection'
              vm[:network_adapters] ||= []
              vm[:network_adapters] << {
                :ip_address => @current_network_connection[:ipAddress],
                :primary => (@current_network_connection[:primaryNetworkConnection] == 'true'),
                :ip_allocation_mode => @current_network_connection[:ipAddressingMode],
                :network => value
              }
            when 'Link'
              vm[:links] = @links
            when 'CoresPerSocket'
              vm[:cores_per_socket] = value
            end
          end

          def parse_start_element(name, attributes, vm)
            case name
            when 'OperatingSystemSection'
              @in_operating_system = true
            when 'HostResource'
              @current_host_resource = extract_attributes(attributes)
            when 'Connection'
              @current_network_connection = extract_attributes(attributes)
            when 'Link'
              # Extract vapp_id from 'up' link.
              vm[:vapp_id] = attr_value('href', attributes).to_s.split('/').last if attr_value('type', attributes) == 'application/vnd.vmware.vcloud.vApp+xml'

              @links << extract_attributes(attributes)
            end
          end

          def parse_vm_attributes(attributes, vm)
            vm_attrs = extract_attributes(attributes)
            vm.merge!(vm_attrs.select { |key, _| %i(href name status type deployed).include?(key) })
            vm[:id]       = vm[:href].split('/').last
            vm[:status]   = human_status(vm[:status])
            vm[:deployed] = vm[:deployed] == 'true'
          end

          def human_status(status)
            case status
            when '-1', -1
              'failed_creation'
            when '0', 0
              'creating'
            when '8', 8
              'off'
            when '4', 4
              'on'
            when '3', 3
              'suspended'
            else
              'unknown'
            end
          end
        end
      end
    end
  end
end
