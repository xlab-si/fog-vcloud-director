require 'fog/vcloud_director/generators/compute/reconfigure_vm'

module Fog
  module VcloudDirector
    class Compute
      class Real
        # Updates VM configuration.
        #
        # This operation is asynchronous and returns a task that you can
        # monitor to track the progress of the request.
        #
        # @param [String] id Object identifier of the VM.
        # @param [Hash] options
        #
        # @option options [String] :name Change the VM's name [required].
        # @option options [String] :description VM description
        #
        # @return [Excon::Response]
        #   * body<~Hash>:
        #     * :Tasks<~Hash>:
        #       * :Task<~Hash>:
        #
        # @see http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.api.reference.doc_51/doc/operations/POST-ReconfigureVm.html
        # @since vCloud API version 5.1
        def post_reconfigure_vm(id, current, options)
          request(
            :body    => Fog::VcloudDirector::Generators::Compute::ReconfigureVm.generate_xml(current, options),
            :expects => 202,
            :headers => {'Content-Type' => 'application/vnd.vmware.vcloud.vm+xml'},
            :method  => 'POST',
            :parser  => Fog::ToHashDocument.new,
            :path    => "vApp/#{id}/action/reconfigureVm"
          )
        end
      end
    end
  end
end
