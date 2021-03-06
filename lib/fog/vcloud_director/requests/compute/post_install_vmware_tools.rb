module Fog
  module VcloudDirector
    class Compute
      class Real
        # Install VMware Tools on a running VM.
        #
        # This operation is asynchronous and returns a task that you can
        # monitor to track the progress of the request.
        #
        # @param [String] id Object identifier of the VM.
        # @return [Excon::Response]
        #   * body<~Hash>:
        #
        # @see http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.api.reference.doc_51/doc/operations/POST-InstallVMwareTools.html
        # @since vCloud API version 1.5
        def post_install_vmware_tools(id)
          request(
            :expects => 202,
            :method  => 'POST',
            :parser  => Fog::ToHashDocument.new,
            :path    => "vApp/#{id}/action/installVMwareTools"
          )
        end
      end
    end
  end
end
