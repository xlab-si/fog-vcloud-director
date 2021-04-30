module Fog
  module VcloudDirector
    class Compute
      class Real
        # deprecated Use {#put_vapp_metadata_item_metadata} instead.
        def put_metadata_value(vm_id, metadata_key, metadata_value)
          Fog::Logger.deprecation("#{self} => #put_metadata_value is deprecated, use #put_vapp_metadata_item_metadata instead [light_black](#{caller.first})[/]")

          body="
          <MetadataValue xmlns=\"http://www.vmware.com/vcloud/v1.5\">
              <Value>#{metadata_value}</Value>
           </MetadataValue>"

          request(
            :body    => body,
            :expects => 202,
            :headers => {'Content-Type' => 'application/vnd.vmware.vcloud.metadata.value+xml'},
            :method  => 'PUT',
            :parser  => Fog::ToHashDocument.new,
            :path    => "vApp/#{vm_id}/metadata/#{URI::DEFAULT_PARSER.escape(metadata_key)}"
          )
        end
      end
    end
  end
end
