require 'fog/vcloud_director/models/compute/vapp'

module Fog
  module VcloudDirector
    class Compute
      class Vapps < Collection

        include Fog::VcloudDirector::Query

        model Fog::VcloudDirector::Compute::Vapp

        attribute :vdc

        def query_type
          "vApp"
        end

        def get_single_vapp(vapp_id)
          item = service.get_vapp(vapp_id).body
          return nil unless item
          %w(:Link).each {|key_to_delete| item.delete(key_to_delete) }
          service.add_id_from_href!(item)
          new(item)
        end

        private

        def get_by_id(item_id)
          item = service.get_vapp(item_id).body
          %w(:Link).each {|key_to_delete| item.delete(key_to_delete) }
          service.add_id_from_href!(item)
          item[:Description] ||= ""
          item
        end

        def item_list
          data = service.get_vdc(vdc.id).body
          return [] if data[:ResourceEntities].empty?
          resource_entities = data[:ResourceEntities][:ResourceEntity]
          items = resource_entities.select { |link| link[:type] == "application/vnd.vmware.vcloud.vApp+xml" }
          items.each{|item| service.add_id_from_href!(item) }
          items
        end
      end
    end
  end
end
