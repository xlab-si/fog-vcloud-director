def expect_vm(vm, vapp_id:, name:, status:, deployed:, os:, ip:, cpu:, cores_per_socket:, cpu_hot:, mem:, mem_hot:, num_hdds:, num_nics:)
  vm.must_be_instance_of Fog::VcloudDirector::Compute::Vm
  vm.type.must_equal 'application/vnd.vmware.vcloud.vm+xml'
  vm.vapp_id.must_equal vapp_id
  vm.name.must_equal name
  vm.description.must_equal ''
  vm.href.must_include '/api/vApp/vm-'
  vm.status.must_equal status
  vm.deployed.must_equal deployed
  vm.operating_system.must_equal os
  vm.ip_address.must_equal ip
  vm.cpu.must_equal cpu
  vm.cores_per_socket.must_equal cores_per_socket
  vm.cpu_hot_add.must_equal cpu_hot
  vm.memory.must_equal mem
  vm.memory_hot_add.must_equal mem_hot
  vm.hard_disks.size.must_equal num_hdds
  vm.network_adapters.size.must_equal num_nics
end

# Basic vApp information which is provided when vApps are only listed for VDC.
def expect_vapp_skeleton(vapp, id:, name:)
  vapp.must_be_instance_of Fog::VcloudDirector::Compute::Vapp
  vapp.type.must_equal 'application/vnd.vmware.vcloud.vApp+xml'
  vapp.href.must_include '/api/vApp/vapp-'
  vapp.id.must_equal id
  vapp.name.must_equal name
end

def expect_vapp(vapp, id:, name:, description:, deployed:, status:, h_status:, lease:, net_section:, net_config:, owner:, maintenance:, num_vms:)
  expect_vapp_skeleton(vapp, :id => id, :name => name)
  vapp.description.must_equal description
  vapp.deployed.must_equal deployed
  vapp.status.must_equal status
  vapp.human_status.must_equal h_status
  vapp.lease_settings.must_equal lease
  vapp.network_section.must_equal net_section
  vapp.network_config.must_equal net_config
  vapp.owner.must_equal owner
  vapp.maintenance.must_equal maintenance
  vapp.vms.size.must_equal num_vms
end
