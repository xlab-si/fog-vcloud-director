require 'fog/vcloud_director/parsers/compute/vm_parser_helper'

module Fog
  module VcloudDirector
    module Parsers
      module Compute
        class Vapp < VcloudDirectorParser
          include VmParserHelper

          def reset
            @response = @vapp = {
              :lease_settings  => 'not-implemented',
              :network_section => 'not-implemented',
              :network_config  => 'not-implemented'
            }
            @in_sections = false
            @parsing_vm  = false
          end

          def start_element(name, attributes)
            super
            return vm_start_element(name, attributes) if @parsing_vm
            vapp_start_element(name, attributes)
          end

          def end_element(name)
            return vm_end_element(name) if @parsing_vm && name != 'Vm'
            vapp_end_element(name)
          end

          private

          def vapp_start_element(name, attributes)
            case name
            when 'VApp'
              vapp_attrs = extract_attributes(attributes)
              @vapp.merge!(vapp_attrs.reject { |key, _| ![:href, :name, :status, :type, :deployed].include?(key) })
              @vapp[:id] ||= id_from_url(@vapp[:href], id_prefix: 'vapp-')
              @vapp[:deployed] = @vapp[:deployed] == 'true'
            when 'LeaseSettingsSection' # this is the first of the sections
              @in_sections = true
              @vapp[:description] ||= '' # if description wasn't parsed by now, then vApp has empty description
            when 'User'
              @vapp[:owner] = attr_value('href', attributes).to_s.split('/').last
            when 'Vm'
              @parsing_vm = true
              vm_reset(@vapp[:id])
              vm_start_element(name, attributes)
            end
          end

          def vapp_end_element(name)
            case name
            when 'Description'
              @vapp[:description] = value unless @in_sections
            when 'InMaintenanceMode'
              @vapp[:maintenance] = value == 'true'
            when 'Vm'
              @parsing_vm = false
              @vapp[:vms] ||= []
              @vapp[:vms] << @curr_vm
            end
          end

          #
          # Nested VMs
          #

          def vm_start_element(name, attributes)
            return parse_vm_attributes(attributes, @curr_vm) if name == 'Vm'
            parse_start_element(name, attributes, @curr_vm)
          end

          def vm_end_element(name)
            parse_end_element(name, @curr_vm)
          end

          def vm_reset(vapp_id)
            @curr_vm                    = initialize_vm
            @curr_vm[:vapp_id]          = vapp_id
            @in_operating_system        = false
            @in_children                = false
            @resource_type              = nil
            @links                      = []
            @element_name               = nil
            @current_network_connection = nil
            @current_host_resource      = nil
          end
        end
      end
    end
  end
end
