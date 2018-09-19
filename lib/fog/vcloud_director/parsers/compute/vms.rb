require 'fog/vcloud_director/parsers/compute/vm_parser_helper'

module Fog
  module VcloudDirector
    module Parsers
      module Compute
        class Vms < VcloudDirectorParser
          include VmParserHelper

          def reset
            @vm = initialize_vm
            @in_operating_system = false
            @in_children = false
            @resource_type = nil
            @response = { :vms => [] }
            @links = []
          end

          def start_element(name, attributes)
            super
            case name
            when 'Vm'
              parse_vm_attributes(attributes, @vm)
            when 'VApp'
              vapp = extract_attributes(attributes)
              @response.merge!(vapp.reject {|key,value| ![:href, :name, :size, :status, :type].include?(key)})
              @response[:id] = @response[:href].split('/').last
            when 'Children'
              @in_children = true
            else
              parse_start_element name, attributes, @vm
            end
          end

          def end_element(name)
            if @in_children
              if name == 'Vm'
                @response[:vms] << @vm
                @vm = {}
              else
                parse_end_element name, @vm
              end
            end
          end
        end
      end
    end
  end
end
