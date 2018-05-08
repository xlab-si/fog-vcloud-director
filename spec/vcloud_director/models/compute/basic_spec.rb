require './spec/spec_helper.rb'

describe Fog::Compute::VcloudDirector do
  describe 'No load errors' do
    [
      Fog::Compute::VcloudDirector::Catalogs,
      Fog::Compute::VcloudDirector::Catalog,
      Fog::Compute::VcloudDirector::CatalogItems,
      Fog::Compute::VcloudDirector::CatalogItem,
      Fog::Compute::VcloudDirector::CustomFields,
      Fog::Compute::VcloudDirector::CustomField,
      Fog::Compute::VcloudDirector::Disks,
      Fog::Compute::VcloudDirector::Disk,
      Fog::Compute::VcloudDirector::Medias,
      Fog::Compute::VcloudDirector::Media,
      Fog::Compute::VcloudDirector::Networks,
      Fog::Compute::VcloudDirector::Network,
      Fog::Compute::VcloudDirector::Organizations,
      Fog::Compute::VcloudDirector::Organization,
      Fog::Compute::VcloudDirector::Tags,
      Fog::Compute::VcloudDirector::Tag,
      Fog::Compute::VcloudDirector::Tasks,
      Fog::Compute::VcloudDirector::Task,
      Fog::Compute::VcloudDirector::TemplateVms,
      Fog::Compute::VcloudDirector::TemplateVm,
      Fog::Compute::VcloudDirector::Vapps,
      Fog::Compute::VcloudDirector::Vapp,
      Fog::Compute::VcloudDirector::VappTemplates,
      Fog::Compute::VcloudDirector::VappTemplate,
      Fog::Compute::VcloudDirector::Vdcs,
      Fog::Compute::VcloudDirector::Vdc,
      Fog::Compute::VcloudDirector::Vms,
      Fog::Compute::VcloudDirector::Vm,
      Fog::Compute::VcloudDirector::VmCustomizations,
      Fog::Compute::VcloudDirector::VmCustomization,
      Fog::Compute::VcloudDirector::VmNetworks,
      Fog::Compute::VcloudDirector::VmNetwork
    ].each do |klass|
      it "Instantiating #{klass}" do
        assert_instance_of(klass, klass.new)
      end
    end
  end
end
