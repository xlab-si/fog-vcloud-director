require './spec/vcr_spec_helper.rb'

describe Fog::Compute::VcloudDirector::Vms do
  let(:subject) { Fog::Compute::VcloudDirector::Vms.new(:service => vcr_service, :vapp => vapp) }
  let(:vapp_id) { 'vapp-fe8d013d-dd2f-4ac6-9e8a-3a4a18e0a62e' }
  let(:vapp)    { Object.new.tap { |vapp| vapp.stubs(:id).returns(vapp_id) } }
  let(:vm_id)   { 'vm-314172f1-1835-4598-b049-5c1d4dce39ad' }

  it '.all' do
    VCR.use_cassette('get_vapp') do
      vms = subject.all
      vms.size.must_equal 2
      expect_vm(
        vms.to_a.detect { |vm| vm.id == vm_id },
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
    end
  end

  it '.get_single_vm' do
    VCR.use_cassette('get_vm') do
      vm = subject.get_single_vm(vm_id)
      puts vm.network_adapters
      expect_vm(
        vm,
        :vapp_id          => vapp_id,
        :name             => 'Web Server VM',
        :status           => 'off',
        :deployed         => false,
        :os               => 'Microsoft Windows Server 2016 (64-bit)',
        :ip               => '',
        :cpu              => 4,
        :cpu_hot          => true,
        :cores_per_socket => 2,
        :mem              => 1024,
        :mem_hot          => true,
        :num_hdds         => 1,
        :num_nics         => 2
      )
    end
  end
end
