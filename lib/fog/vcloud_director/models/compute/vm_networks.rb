require 'fog/vcloud_director/models/compute/vm_network'

module Fog
  module VcloudDirector
    class Compute
      class VmNetworks < Collection
        model Fog::VcloudDirector::Compute::VmNetwork

        attribute :vm

        def get(id)
          data = service.get_vm_network(id).body
          new(data)
        end
      end
    end
  end
end
