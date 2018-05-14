require './spec/vcr_spec_helper.rb'

describe Fog::Compute::VcloudDirector::Vapps do
  let(:subject) { Fog::Compute::VcloudDirector::Vapps.new(:service => vcr_service, :vdc => vdc) }
  let(:vdc_id)  { 'cf6ea964-a67f-4ba1-b69e-3dd5d6cb0c89' }
  let(:vdc)     { Object.new.tap { |vapp| vapp.stubs(:id).returns(vdc_id) } }
  let(:vapp_id) { 'vapp-fe8d013d-dd2f-4ac6-9e8a-3a4a18e0a62e' }
  let(:vm_id)   { 'vm-314172f1-1835-4598-b049-5c1d4dce39ad' }
  let(:vm2_id)  { 'vm-8dc9990c-a55a-418e-8e21-5942a20b93ef' }

  it '.all' do
    VCR.use_cassette('get_vapps') do
      vapps = subject.all
      vapps.size.must_equal 7
      expect_vapp_skeleton(
        vapps.detect { |vapp| vapp.id == vapp_id },
        :id   => vapp_id,
        :name => 'cfme-vapp'
      )
    end
  end

  it '.get_single_vapp' do
    VCR.use_cassette('get_vapp') do
      vapp = subject.get_single_vapp(vapp_id)
      expect_vapp(
        vapp,
        :id          => vapp_id,
        :name        => 'cfme-vapp',
        :description => '',
        :deployed    => false,
        :status      => 'off',
        :lease       => nil,
        :net_section => nil,
        :net_config  => nil,
        :owner       => 'e0d6e74d-efde-49fe-b19f-ace7e55b68dd',
        :maintenance => false,
        :num_vms     => 2
      )
      expect_vm(
        vapp.vms.detect { |vm| vm.id == vm_id },
        :vapp_id          => vapp_id,
        :name             => 'Web Server VM',
        :status           => 'off',
        :deployed         => false,
        :os               => 'Microsoft Windows Server 2016 (64-bit)',
        :ip               => '',
        :cpu              => 4,
        :cores_per_socket => 2,
        :cpu_hot          => false,
        :mem              => 1024,
        :mem_hot          => false,
        :num_hdds         => 1,
        :num_nics         => 2
      )
      expect_vm(
        vapp.vms.detect { |vm| vm.id == vm2_id },
        :vapp_id          => vapp_id,
        :name             => 'Databasy Machiny',
        :status           => 'off',
        :deployed         => false,
        :os               => 'Microsoft Windows Server 2016 (64-bit)',
        :ip               => '192.168.43.2',
        :cpu              => 8,
        :cores_per_socket => 4,
        :cpu_hot          => true,
        :mem              => 4096,
        :mem_hot          => true,
        :num_hdds         => 3,
        :num_nics         => 2
      )
    end
  end
end
