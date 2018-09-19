require 'fog/vcloud_director/models/compute/template_vm'

module Fog
  module VcloudDirector
    class Compute
      class TemplateVms < Collection

        include Fog::VcloudDirector::Query

        model Fog::VcloudDirector::Compute::TemplateVm

        attribute :vapp_template


        def get_single_template_vm(vm_id)
          item = service.get_template_vm(vm_id).body
          return nil unless item
          new(item[:vm])
        end

        def query_type
          "vm"
        end

        private

        def get_by_id(item_id)
          item = item_list.find{ |vm| vm[:id] == item_id }
          item
        end

        def item_list
          data = service.get_template_vms(vapp_template.id).body  # vapp.id
          items = data[:vms]
          items
        end
      end
    end
  end
end
