require './spec/vcr_spec_helper.rb'

describe Fog::VcloudDirector::Compute::Vms do
  let(:subject) { Fog::VcloudDirector::Compute::Vms.new(:service => vcr_service, :vapp => vapp) }
  let(:vapp_id) { 'vapp-fe8d013d-dd2f-4ac6-9e8a-3a4a18e0a62e' }
  let(:vapp)    { Object.new.tap { |vapp| vapp.stubs(:id).returns(vapp_id) } }
  let(:vm_id)   { 'vm-314172f1-1835-4598-b049-5c1d4dce39ad' }
  let(:vm2_id)  { 'vm-8dc9990c-a55a-418e-8e21-5942a20b93ef' }

  describe '.all' do
    it 'regular' do
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

    it 'when vm has no disks and nics' do
      VCR.use_cassette('get_vapp-emptyvm') do
        vms = subject.all
        vms.size.must_equal 2
        expect_vm(
          vms.to_a.detect { |vm| vm.id == vm2_id },
          :vapp_id          => vapp_id,
          :name             => 'Databasy Machiny',
          :status           => 'off',
          :deployed         => false,
          :os               => 'Microsoft Windows Server 2016 (64-bit)',
          :ip               => '',
          :cpu              => 2,
          :cores_per_socket => 1,
          :cpu_hot          => false,
          :mem              => 1024,
          :mem_hot          => false,
          :num_hdds         => 0,
          :num_nics         => 0
        )
      end
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
