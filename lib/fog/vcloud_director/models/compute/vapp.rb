module Fog
  module VcloudDirector
    class Compute
      class Vapp < Model
        identity  :id

        attribute :name
        attribute :type
        attribute :href
        attribute :description, :aliases => :Description
        attribute :deployed, :type => :boolean
        attribute :status
        attribute :lease_settings
        attribute :network_section
        attribute :network_config
        attribute :owner
        attribute :maintenance, :type => :boolean

        def initialize(attributes = {})
          # Memorize VMs because their full XML description was already included in the vApp XML description.
          # Instead simple Array we rather store as Collection in order to provide common interface e.g.
          #    vapp.vms.all
          #    vapp.vms.get_by_name
          if (vms = attributes.delete(:vms))
            @vms = Fog::VcloudDirector::Compute::Vms.new(
              :vapp    => self,
              :service => attributes[:service]
            ).with_item_list(Array(vms))
          end

          super(attributes)
        end

        def vms(force: false)
          # Return memorized Collection that we parsed based on vApp XML description. This way we prevent
          # additional API request to be made for each VM in a vApp.
          return @vms unless @vms.nil? || force

          requires :id
          service.vms(:vapp => self)
        end

        def tags
          requires :id
          service.tags(:vm => self)
        end

        def custom_fields
          requires :id
          service.custom_fields( :vapp => self)
        end

        # https://pubs.vmware.com/vcd-80/index.jsp#com.vmware.vcloud.api.sp.doc_90/GUID-843BE3AD-5EF6-4442-B864-BCAE44A51867.html
        def human_status
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

        # @param [String] action The specified action is applied to all virtual
        #   machines in the vApp. All values other than **default** ignore
        #   actions, order, and delay specified in the StartupSection. One of:
        # * powerOff (Power off the virtual machines. This is the default
        #   action if this attribute is missing or empty)
        # * suspend (Suspend the virtual machines)
        # * shutdown (Shut down the virtual machines)
        # * force (Attempt to power off the virtual machines. Failures in
        #   undeploying the virtual machine or associated networks are ignored.
        #   All references to the vApp and its virtual machines are removed
        #   from the database)
        # * default (Use the actions, order, and delay specified in the
        #   StartupSection)
        def undeploy(action='powerOff')
          begin
            response = service.post_undeploy_vapp(id, :UndeployPowerAction => action)
          rescue Fog::VcloudDirector::Compute::BadRequest => ex
            Fog::Logger.debug(ex.message)
            return false
          end
          service.process_task(response.body)
        end

        # Power off all VMs in the vApp.
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

        # Power on all VMs in the vApp.
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

        # Reboot all VMs in the vApp.
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

        # Reset all VMs in the vApp.
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

        # Shut down all VMs in the vApp.
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

        # Suspend all VMs in the vApp.
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

        def destroy
          requires :id
          begin
            response = service.delete_vapp(id)
          rescue Fog::VcloudDirector::Compute::BadRequest => ex
            Fog::Logger.debug(ex.message)
            return false
          end
          service.process_task(response.body)
        end
      end
    end
  end
end
