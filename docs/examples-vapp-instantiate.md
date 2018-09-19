# vApp Instantiate Examples
In this document we provide examples of vapp instantiation.

## Minimal Example (no customization)

```ruby
service = Fog::VcloudDirector::Compute.new(...)
options = {
  :stack_name => 'miha-test-vapp',
  :template   => 'vappTemplate-e269eba3-f7d4-449c-b960-a313807b3925',
  :deploy     => false,
  :powerOn    => false,
  :vdc_id     => 'cf6ea964-a67f-4ba1-b69e-3dd5d6cb0c89'
}
service.instantiate_template(options)
``` 

## Real-world Example
Example below instantiates vApp named "my-vapp" based on a vApp template provided
[here](./web-server-with-db-vapp.xml). Two virtual machines are defined  in template
("DB VM" and "Web VM") and with this provisioning request we customize both.

We also customize vApp networks: we edit existing one ("Private network 43") and
add a new one ("Default Network"). For each NIC on each VM we then specify what
network does it connect to and how.

```ruby
service = Fog::VcloudDirector::Compute.new(...)
options = {
  :stack_name    => 'my-vapp',
  :template      => 'vappTemplate-e269eba3-f7d4-449c-b960-a313807b3925',
  :deploy        => false,
  :powerOn       => false,
  :vdc_id        => 'cf6ea964-a67f-4ba1-b69e-3dd5d6cb0c89',
  :source_vms    => [
    # First VM (DB VM).
    {
      :name                => 'DB VM',
      :vm_id               => 'vm-595416d8-2b1a-4f45-86c7-56244a548f1a',
      # Hostname.
      :guest_customization => { :ComputerName => 'db-vm' },
      :networks            => [
        # NIC 0 (we connect to Default Network in DHCP mode).
        {
          :networkName             => 'Default Network',
          :IpAddressAllocationMode => 'DHCP',
          :IpAddress               => nil,
          :IsConnected             => false
        }
      ],
      :hardware            => {
        :cpu    => { :num_cores => 1, :cores_per_socket => 1 },
        # Increase MEM capacity to 1 GB.
        :memory => { :quantity_mb => 1024 },
        # Increase disk capacity to 40 GB.
        :disk   => [{ :id => '2000', :capacity_mb => 40960 }]
      }
    },
    # Second VM (Web VM).
    {
      :name                => 'Web VM',
      :vm_id               => 'vm-a436a184-b2cd-4c6d-b274-98caa6c3c7a1',
      :guest_customization => { :ComputerName => 'web-vm' },
      :networks=>[
        # NIC 0 (we connect to Private network 43 in static IP mode).
        {
          :networkName             => 'Private network 43',
          :IpAddressAllocationMode => 'MANUAL',
          :IpAddress               => '192.168.43.100',
          :IsConnected             => true
        },
        # NIC 1 (we connect to Default Network in DHCP mode).
        {
          :networkName             => 'Default Network',
          :IpAddressAllocationMode => 'DHCP',
          :IpAddress               => nil,
          :IsConnected             => false
        }
      ],
      :hardware => {
        :cpu    => { :num_cores => 1, :cores_per_socket => 1 },
        :memory => { :quantity_mb => 512 },
        :disk   => [{ :id => "2000", :capacity_mb => 5120 }]
      }      
    }
  ],
  # Customize vApp networks that the two VMs connect to.
  :vapp_networks => [
    # Modify existing vApp network.
    {
      :name       => 'Private network 43',
      :parent     => 'b915be99-1471-4e51-bcde-da2da791b98f',
      :fence_mode => 'bridged',
      :subnet     => [
        {
          :gateway => '192.168.43.1',
          :netmask => '255.255.255.0',
          :dns1    => '192.168.43.1',
          :dns2    => nil
        }
      ]
    },
    # Add a new vApp network (is not specified in template).
    {
      :name       => 'Default Network',
      :parent     => nil,
      :fence_mode => 'isolated',
      :subnet     => [
        {
          :gateway => '192.168.10.1',
          :netmask => '255.255.255.0',
          :dns1    => nil,
          :dns2    => nil
        }
      ]
    }
  ]
}
service.instantiate_template(options)
``` 
