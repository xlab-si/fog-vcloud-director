module Fog
  module VcloudDirector
    class Compute
      class Real
        # Retrieve a MKS screen ticket that you can use
        # to gain access to the console of a running VM.
        #
        # @param [String] id Object identifier of the VM.
        # @return [Excon::Response]
        #   * body<~Hash>:
        #
        # @raise [Fog::VcloudDirector::Compute::Conflict]
        #
        # https://pubs.vmware.com/vcd-80/index.jsp?topic=%2Fcom.vmware.vcloud.api.reference.doc_90%2Fdoc%2Foperations%2FPOST-AcquireMksTicket.html
        # @since vCloud API version 5.5
        def post_acquire_mks_ticket(id)
          request(
            :expects => 200,
            :method  => 'POST',
            :parser  => Fog::ToHashDocument.new,
            :path    => "vApp/#{id}/screen/action/acquireMksTicket"
          )
        end
      end
    end
  end
end
