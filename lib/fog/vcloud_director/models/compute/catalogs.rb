require 'fog/vcloud_director/models/compute/catalog'
require 'fog/vcloud_director/models/compute/catalog_item'

module Fog
  module VcloudDirector
    class Compute
      class Catalogs < Collection
        model Fog::VcloudDirector::Compute::Catalog

        attribute :organization

        def get_single_catalog_item(item_id)
          item = service.get_catalog_item(item_id).body
          return nil unless item
          item[:vapp_template_id] = item[:Entity][:href].split('/').last
          Fog::VcloudDirector::Compute::CatalogItem.new(item.merge({ :service => service, :collection => [] }))
        end

        private

        def get_by_id(item_id)
          item = service.get_catalog(item_id).body
          %w(:CatalogItems :Link).each {|key_to_delete| item.delete(key_to_delete) }
          service.add_id_from_href!(item)
          item
        end

        def item_list
          data = service.get_organization(organization.id).body
          items = data[:Link].select { |link| link[:type] == "application/vnd.vmware.vcloud.catalog+xml" }
          items.each{|item| service.add_id_from_href!(item) }
          items
        end
      end
    end
  end
end
