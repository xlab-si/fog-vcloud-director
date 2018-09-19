require 'fog/vcloud_director/models/compute/vm_customization'

module Fog
  module VcloudDirector
    class Compute
      class Vm < Model
        identity  :id

        attribute :vapp_id
        attribute :name
        attribute :type
        attribute :description
        attribute :href
        attribute :status
        attribute :deployed
        attribute :operating_system
        attribute :ip_address
        attribute :cpu, :type => :integer
        attribute :cores_per_socket, :type => :integer
        attribute :cpu_hot_add, :type => :boolean
        attribute :memory, :type => :integer
        attribute :memory_hot_add, :type => :boolean
        attribute :hard_disks, :aliases => :disks
        attribute :network_adapters

        def reload
          # when collection.vapp is nil, it means it's fatherless,
          # vms from different vapps are loaded in the same collection.
          # This situation comes from a "query" result
          collection.vapp.nil? ? reload_single_vm : super
        end

        def reload_single_vm
          return unless data = begin
            collection.get_single_vm(identity)
          rescue Excon::Errors::SocketError
            nil
          end
          # these two attributes don't exists in the get_single_vm response
          # that's why i use the old attributes
          data.attributes[:vapp_id] = attributes[:vapp_id]
          data.attributes[:vapp_name] = attributes[:vapp_name]
          new_attributes = data.attributes
          merge_attributes(new_attributes)
          self
        end

        # Power off the VM.
        def power_off
          requires :id
          begin
            response = service.post_power_off_vapp(id)
          rescue Fog::VcloudDirector::Compute::BadRequest => ex
            Fog::Logger.debug(ex.message)
            return false
          end
          service.process_task(response.body)
        end

        # Power on the VM.
        def power_on
          requires :id
          begin
            response = service.post_power_on_vapp(id)
          rescue Fog::VcloudDirector::Compute::BadRequest => ex
            Fog::Logger.debug(ex.message)
            return false
          end
          service.process_task(response.body)
        end

        # Reboot the VM.
        def reboot
          requires :id
          begin
            response = service.post_reboot_vapp(id)
          rescue Fog::VcloudDirector::Compute::BadRequest => ex
            Fog::Logger.debug(ex.message)
            return false
          end
          service.process_task(response.body)
        end

        # Reset the VM.
        def reset
          requires :id
          begin
            response = service.post_reset_vapp(id)
          rescue Fog::VcloudDirector::Compute::BadRequest => ex
            Fog::Logger.debug(ex.message)
            return false
          end
          service.process_task(response.body)
        end

        def undeploy
          requires :id
          begin
            response = service.post_undeploy_vapp(id)
          rescue Fog::VcloudDirector::Compute::BadRequest => ex
            Fog::Logger.debug(ex.message)
            return false
          end
          service.process_task(response.body)
        end

        # Shut down the VM.
        def shutdown
          requires :id
          begin
            response = service.post_shutdown_vapp(id)
          rescue Fog::VcloudDirector::Compute::BadRequest => ex
            Fog::Logger.debug(ex.message)
            return false
          end
          service.process_task(response.body)
        end

        # Suspend the VM.
        def suspend
          requires :id
          begin
            response = service.post_suspend_vapp(id)
          rescue Fog::VcloudDirector::Compute::BadRequest => ex
            Fog::Logger.debug(ex.message)
            return false
          end
          service.process_task(response.body)
        end

        def tags
          requires :id
          service.tags(:vm => self)
        end

        def customization
          requires :id
          data = service.get_vm_customization(id).body
          service.vm_customizations.new(data)
        end

        def network
          requires :id
          data = service.get_vm_network(id).body
          service.vm_networks.new(data)
        end

        def disks
          requires :id
          service.disks(:vm => self)
        end
        
        # Reconfigure a VM using any of the options documented in
        # post_reconfigure_vm
        def reconfigure(options, current: nil)
          # Fetch current XML.
          current ||= service.get_vapp(id, :parser => 'xml').body
          # Let post_reconfigure_vm apply modifications.
          response = service.post_reconfigure_vm(id, current, options)
          service.process_task(response.body)

          # TODO: apply modifications on current VM instance.
        end
        
        def ready?
          reload
          status == 'on'
        end

        def vapp
          # get_by_metadata returns a vm collection where every vapp parent is orpahn
          collection.vapp ||= service.vapps.get(vapp_id)
        end
      end
    end
  end
end
