# VM Reconfiguration Examples
In this document we provide examples of VM reconfiguration.

## Hardware Reconfiguration Example
This example demonstrates basic hardware customization parameters. Raw content of parameter
`xml` can be examined [here](./vm-to-reconfigure.xml).

```ruby
service = Fog::VcloudDirector::Compute.new(...)

# Obtain nokogiri-parsed XML representation of VM.
xml = service.get_vapp('vm-8dc9990c-a55a-418e-8e21-5942a20b93ef', :parser => 'xml').body

# Decide what hardware options to customize.
options = {
    :name        => 'DB VM',                           # new VM name
    :description => 'Some Description',                # new VM description
    :hardware    => {
        :memory => { :quantity_mb => 4096 },           # set memory to 4GB
        :cpu    => { :num_cores => 4, :cores_per_socket => 1 },
        :disk   => [
            { :id => '2000', :capacity_mb => 5*1024 }, # increase disk 2000 to 5GB
            { :id => '2001', :capacity_mb => -1 },     # delete disk 2001
            { :capacity_mb => 1*1024 }                 # add a new disk of size 1GB
        ]
    }
}

# Actually perform customization.
service.post_reconfigure_vm(
  'vm-8dc9990c-a55a-418e-8e21-5942a20b93ef',
  xml,
  options
)
``` 

**NOTE**: If you omit `:hardware` key from options, then reconfiguration request will be
simplified by omitting entire VirtualHardwareSection from payload XML. So please prefer
omitting the `:hardware` key over passing `:hardware => {}` in order to reduce network load. 

## Network Connection Reconfiguration Example
This example demonstrates basic NIC connection customization that allows you to modify what
vApp network is each VM's NIC connected to, among with other NIC options.

```ruby
service = Fog::VcloudDirector::Compute.new(...)

# Obtain nokogiri-parsed XML representation of VM.
xml = service.get_vapp('vm-8dc9990c-a55a-418e-8e21-5942a20b93ef', :parser => 'xml').body

# Update NIC#0.
options = {    
    :networks => [
        {
          :idx       => 0, # pick NIC#0 to apply below modifications to
           
          :new_idx   => 5,                   # assign new NIC virtual index to 5 (instead 0) 
          :name      => 'Localhost',         # plug NIC to vApp network called 'Localhost'
          :mac       => '11:22:33:44:55:66', # set NIC MAC address
          :mode      => 'MANUAL',            # set NIC IP address allocation mode
          :ip        => '1.2.3.4',           # set NIC IP address
          :type      => 'PCNet32',           # set NIC adapter type
          :primary   => true,                # make this NIC primary
          :needs     => true,                # mark NIC as 'needs customization'
          :connected => true                 # mark NIC as connected
        }
    ]
}

# Actually perform customization.
service.post_reconfigure_vm(
  'vm-8dc9990c-a55a-418e-8e21-5942a20b93ef',
  xml,
  options
)
``` 

### Unplugging NIC
Please use vCloud's reserved network name `'none'` to unplug NIC from all vApp networks.
NIC will be marked as disconnected automatically:

```ruby
options = {    
    :networks => [
        {
          :idx  => 0,
          :name => 'none'
        }
    ]
}
```

### Removing NIC
Please set `:new_idx => -1` to remove NIC from the VM.

```ruby
options = {    
    :networks => [
        {
          :idx     => 0,
          :new_idx => -1
        }
    ]
}
```

### Adding a New NIC
Please set `:idx => nil` to add a new NIC and specify its index with `:new_idx` key. You can
specify any other NIC options as well, of course, like what vApp network to plug the new NIC
to:

```ruby
options = {    
    :networks => [
        {
          :idx     => nil,
          :new_idx => 1,
          :name    => 'Localhost'
        }
    ]
}
```
