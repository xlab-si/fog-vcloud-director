def expect_vm(vm, vapp_id:, name:, status:, deployed:, os:, ip:, cpu:, cores_per_socket:, mem:, num_hdds:, num_nics:)
  vm.must_be_instance_of Fog::Compute::VcloudDirector::Vm
  vm.type.must_equal 'application/vnd.vmware.vcloud.vm+xml'
  # vm.vapp_id.must_equal vapp_id # TODO(miha-plesko) update parser to fetch this value from single VM response as well.
  vm.name.must_equal name
  vm.description.must_equal ''
  vm.href.must_include '/api/vApp/vm-'
  vm.status.must_equal status
  vm.deployed.must_equal deployed
  vm.operating_system.must_equal os
  vm.ip_address.must_equal ip
  vm.cpu.must_equal cpu
  vm.cores_per_socket.must_equal cores_per_socket
  vm.memory.must_equal mem
  vm.hard_disks.size.must_equal num_hdds
  vm.network_adapters.size.must_equal num_nics
end
