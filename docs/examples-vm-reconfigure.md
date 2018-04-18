# VM Reconfiguration Examples
In this document we provide examples of VM reconfiguration.

## Hardware Reconfiguration Example
This example demonstrates basic hardware customization parameters. Raw content of parameter
`xml` can be examined [here](./vm-to-reconfigure.xml).

```ruby
service = Fog::Compute::VcloudDirector.new(...)

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
