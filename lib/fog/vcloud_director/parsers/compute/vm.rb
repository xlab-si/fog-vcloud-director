require 'fog/vcloud_director/parsers/compute/vm_parser_helper'

module Fog
  module VcloudDirector
    module Parsers
      module Compute
        class Vm < VcloudDirectorParser
          include VmParserHelper

          def reset
            @in_operating_system = false
            @in_children = false
            @resource_type = nil
            @response = { :vm => initialize_vm }
            @links = []
          end

          def start_element(name, attributes)
            super
            return parse_vm_attributes(attributes, @response[:vm]) if name == 'Vm'
            parse_start_element name, attributes, @response[:vm]
          end

          def end_element(name)
            parse_end_element name, @response[:vm]
          end
        end
      end
    end
  end
end
