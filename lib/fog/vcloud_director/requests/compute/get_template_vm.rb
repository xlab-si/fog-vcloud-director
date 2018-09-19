module Fog
  module VcloudDirector
    class Compute
      class Real
        require 'fog/vcloud_director/parsers/compute/vm'

        # Retrieve a vApp or VM.
        #
        # @note This should probably be deprecated.
        #
        # @param [String] id Object identifier of the vApp or VM.
        # @return [Excon::Response]
        #   * body<~Hash>:
        #
        # @see #get_vapp
        def get_template_vm(id)
          request(
            :expects    => 200,
            :idempotent => true,
            :method     => 'GET',
            :parser     => Fog::VcloudDirector::Parsers::Compute::Vm.new,
            :path       => "vAppTemplate/#{id}"
          )
        end
      end
    end
  end
end
