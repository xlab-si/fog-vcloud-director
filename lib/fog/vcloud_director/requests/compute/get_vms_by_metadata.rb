module Fog
  module VcloudDirector
    class Compute
      class Real
        require 'fog/vcloud_director/parsers/compute/vms_by_metadata'

        # @see #get_vms_in_lease_by_query
        def get_vms_by_metadata(key,value)
          request(
            :expects    => 200,
            :idempotent => true,
            :method     => 'GET',
            :parser     => Fog::VcloudDirector::Parsers::Compute::VmsByMetadata.new,
            :path       => "vms/query?format=records&filter=metadata:#{key}==STRING:#{value}"
          )
        end
      end
    end
  end
end
