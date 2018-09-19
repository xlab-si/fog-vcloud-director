require './spec/spec_helper.rb'

describe Fog::VcloudDirector::Compute do
  describe 'No load errors' do
    [
      Fog::VcloudDirector::Compute::Catalogs,
      Fog::VcloudDirector::Compute::Catalog,
      Fog::VcloudDirector::Compute::CatalogItems,
      Fog::VcloudDirector::Compute::CatalogItem,
      Fog::VcloudDirector::Compute::CustomFields,
      Fog::VcloudDirector::Compute::CustomField,
      Fog::VcloudDirector::Compute::Disks,
      Fog::VcloudDirector::Compute::Disk,
      Fog::VcloudDirector::Compute::Medias,
      Fog::VcloudDirector::Compute::Media,
      Fog::VcloudDirector::Compute::Networks,
      Fog::VcloudDirector::Compute::Network,
      Fog::VcloudDirector::Compute::Organizations,
      Fog::VcloudDirector::Compute::Organization,
      Fog::VcloudDirector::Compute::Tags,
      Fog::VcloudDirector::Compute::Tag,
      Fog::VcloudDirector::Compute::Tasks,
      Fog::VcloudDirector::Compute::Task,
      Fog::VcloudDirector::Compute::TemplateVms,
      Fog::VcloudDirector::Compute::TemplateVm,
      Fog::VcloudDirector::Compute::Vapps,
      Fog::VcloudDirector::Compute::Vapp,
      Fog::VcloudDirector::Compute::VappTemplates,
      Fog::VcloudDirector::Compute::VappTemplate,
      Fog::VcloudDirector::Compute::Vdcs,
      Fog::VcloudDirector::Compute::Vdc,
      Fog::VcloudDirector::Compute::Vms,
      Fog::VcloudDirector::Compute::Vm,
      Fog::VcloudDirector::Compute::VmCustomizations,
      Fog::VcloudDirector::Compute::VmCustomization,
      Fog::VcloudDirector::Compute::VmNetworks,
      Fog::VcloudDirector::Compute::VmNetwork
    ].each do |klass|
      it "Instantiating #{klass}" do
        assert_instance_of(klass, klass.new)
      end
    end
  end
end
