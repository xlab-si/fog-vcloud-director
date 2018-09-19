require './spec/spec_helper.rb'

describe Fog::VcloudDirector::Generators::Compute::InstantiateVappTemplateParams do
  describe 'Complete xml' do
    let(:xml) do
      params = {
        :name => 'VAPP_NAME',
        :Description => 'MY VAPP',
        :InstantiationParams => {
          :NetworkConfig => [
            {
              :networkName => 'NETWORK',
              :networkHref => 'http://vcloud/api/network/123456789',
              :fenceMode => 'bridged'
            }
          ]
        },
        :Source => 'http://vcloud/vapp_template/1234',
        :source_vms => [
          {
            :name => 'VM1',
            :href => 'http://vcloud/api/vm/12345',
            :StorageProfileHref => 'http://vcloud/storage/123456789',
            :hardware => {
              :memory => { :quantity_mb => 1024, :reservation => 0, :limit => 1, :weight => 2 },
              :cpu => { :num_cores => 4, :cores_per_socket => 2, :reservation => 0, :limit => 1, :weight => 2 },
              :disks => [
                { :id => 'ID1', :size => 1000 },
                { :id => 'ID2', :size => 2000 }
              ]
            }
          },
          {
            :name => 'VM2',
            :href => 'http://vcloud/api/vm/56789',
            :StorageProfileHref => 'http://vcloud/storage/123456789'
          }
        ]

      }

      output = Fog::VcloudDirector::Generators::Compute::InstantiateVappTemplateParams.new(params).generate_xml
      Nokogiri::XML(output)
    end

    it 'Generates InstantiateVAppTemplateParams' do
      xml.xpath('//InstantiateVAppTemplateParams').must_be_instance_of Nokogiri::XML::NodeSet
    end

    it 'Has a valid Network' do
      xml.xpath('//xmlns:NetworkConfig')[0].attr('networkName').must_equal 'NETWORK'
      xml.xpath('//xmlns:ParentNetwork')[0].attr('href').must_equal 'http://vcloud/api/network/123456789'
    end

    it 'Has valid source VAPP info' do
      node = xml.xpath('//xmlns:Source[@href="http://vcloud/vapp_template/1234"]')
      node.length.must_equal 1
    end

    it 'Has valid source VM info' do
      xml.xpath('//xmlns:StorageProfile[@href="http://vcloud/storage/123456789"]').length.must_equal 2
    end

    it 'Allows New VM Parameters' do
      nodes = xml.xpath('//xmlns:VmGeneralParams')
      nodes.length.must_equal 2
    end
  end

  describe 'Hardware customization' do
    [
      {
        case: 'nil hardware section',
        hardware: nil,
        :expect => ->(out) {}
      },
      {
        case: 'nil memory section',
        hardware: {
          :memory => nil
        },
        :expect => ->(out) {}
      },
      {
        case: 'minimal memory section',
        hardware: {
          :memory => { :quantity_mb => 1024 }
        },
        :expect => lambda do |out|
          mems = hw_items_by_type(out, 4)
          mems.count.must_equal 1
          mem = mems.first
          common_mem_assertions(mem)
          mem.xpath('./rasd:VirtualQuantity').text.must_equal('1024')
          mem.xpath('./rasd:Reservation').must_be_empty
          mem.xpath('./rasd:Limit').must_be_empty
          mem.xpath('./rasd:Weight').must_be_empty
        end
      },
      {
        case: 'full memory section',
        hardware: {
          :memory => { :quantity_mb => 1024, :reservation => 0, :limit => 1, :weight => 2 }
        },
        :expect => lambda do |out|
          mems = hw_items_by_type(out, 4)
          mems.count.must_equal 1
          mem = mems.first
          common_mem_assertions(mem)
          mem.xpath('./rasd:VirtualQuantity').text.must_equal('1024')
          mem.xpath('./rasd:Reservation').text.must_equal('0')
          mem.xpath('./rasd:Limit').text.must_equal('1')
          mem.xpath('./rasd:Weight').text.must_equal('2')
        end
      },
      {
        case: 'nil cpu section',
        hardware: {
          :cpu => nil
        },
        :expect => ->(out) {}
      },
      {
        case: 'minimal cpu section',
        hardware: {
          :cpu => { :num_cores => 4 }
        },
        :expect => lambda do |out|
          cpus = hw_items_by_type(out, 3)
          cpus.count.must_equal 1
          cpu = cpus.first
          common_cpu_assertions(cpu)
          cpu.xpath('./rasd:VirtualQuantity').text.must_equal('4')
          cpu.xpath('./rasd:Reservation').must_be_empty
          cpu.xpath('./rasd:Limit').must_be_empty
          cpu.xpath('./rasd:Weight').must_be_empty
          cpu.xpath('./vmw:CoresPerSocket').must_be_empty
        end
      },
      {
        case: 'full cpu section',
        hardware: {
          :cpu => { :num_cores => 4, :cores_per_socket => 2, :reservation => 0, :limit => 1, :weight => 2 }
        },
        :expect => lambda do |out|
          cpus = hw_items_by_type(out, 3)
          cpus.count.must_equal 1
          cpu = cpus.first
          common_cpu_assertions(cpu)
          cpu.xpath('./rasd:VirtualQuantity').text.must_equal('4')
          cpu.xpath('./rasd:Reservation').text.must_equal('0')
          cpu.xpath('./rasd:Limit').text.must_equal('1')
          cpu.xpath('./rasd:Weight').text.must_equal('2')
          cpu.xpath('./vmw:CoresPerSocket').text.must_equal('2')
        end
      },
      {
        case: 'nil disk section',
        hardware: {
          :disk => nil
        },
        :expect => ->(out) {}
      },
      {
        case: 'minimal disk section',
        hardware: {
          :disk => { :id => 2000, :capacity_mb => 1024 }
        },
        :expect => lambda do |out|
          hdds = hw_items_by_type(out, 17)
          hdds.count.must_equal 1
          hdd = hdds.first
          common_hw_assertions(hdd)
          hdd.xpath('./rasd:InstanceID').text.must_equal('2000')
          hdd.xpath('./rasd:HostResource').text.must_be_empty
          hdd.xpath('./rasd:HostResource/@vcloud:capacity').text.must_equal('1024')
          hdd.xpath('./rasd:HostResource/@vcloud:busType').must_be_empty
          hdd.xpath('./rasd:HostResource/@vcloud:busSubType').must_be_empty
          hdd.xpath('./rasd:AddressOnParent').must_be_empty
        end
      },
      {
        case: 'full disk section',
        hardware: {
          :disk => { :id => 2000, :capacity_mb => 1024, :address => 0, :type => 6, :subtype => 'VirtualSCSI' }
        },
        :expect => lambda do |out|
          hdds = hw_items_by_type(out, 17)
          hdds.count.must_equal 1
          hdd = hdds.first
          common_hw_assertions(hdd)
          hdd.xpath('./rasd:InstanceID').text.must_equal('2000')
          hdd.xpath('./rasd:HostResource').text.must_be_empty
          hdd.xpath('./rasd:HostResource/@vcloud:capacity').text.must_equal('1024')
          hdd.xpath('./rasd:HostResource/@vcloud:busType').text.must_equal('6')
          hdd.xpath('./rasd:HostResource/@vcloud:busSubType').text.must_equal('VirtualSCSI')
          hdd.xpath('./rasd:AddressOnParent').text.must_equal('0')
        end
      },
      {
        case: 'two disks',
        hardware: {
          :disk => [
            { :id => 2000, :capacity_mb => 1024 },
            { :id => 3000, :capacity_mb => 2048 }
          ]
        },
        :expect => lambda do |out|
          hdds = hw_items_by_type(out, 17)
          hdds.count.must_equal 2
          hdds.each { |hdd| common_hw_assertions(hdd) }
        end
      }
    ].each do |args|
      it args[:case].to_s do
        input = {
          :name => 'VAPP_NAME',
          :source_vms => [
            {
              :name => 'VM1',
              :hardware => args[:hardware]
            }
          ]
        }
        output = Fog::VcloudDirector::Generators::Compute::InstantiateVappTemplateParams.new(input).generate_xml
        args[:expect].call(Nokogiri::XML(output))
      end
    end

    def self.hw_items_by_type(xml, type)
      xml.xpath("//xmlns:SourcedItem/xmlns:InstantiationParams/ovf:VirtualHardwareSection/ovf:Item[./rasd:ResourceType = '#{type}']")
    end

    def self.common_hw_assertions(xml)
      # RASD elements must be alphabetically sorted
      children = xml.children.select { |n| n.type == 1 }.map { |n| "#{n.namespace.prefix}:#{n.name}" }
      sorted = children.sort
      children.must_equal(sorted)

      xml.xpath('./rasd:ElementName').text.length.must_be :>, 0
      xml.xpath('./rasd:InstanceID').text.length.must_be :>, 0
    end

    def self.common_mem_assertions(xml)
      common_hw_assertions(xml)
      xml.xpath('./rasd:VirtualQuantity').text.length.must_be :>, 0
      xml.xpath('./rasd:AllocationUnits').text.must_equal('byte * 2^20')
    end

    def self.common_cpu_assertions(xml)
      common_hw_assertions(xml)
      xml.xpath('./rasd:VirtualQuantity').text.length.must_be :>, 0
      xml.xpath('./rasd:AllocationUnits').text.must_equal('hertz * 10^6')
    end
  end

  describe 'vApp Network customization' do
    [
      {
        :case          => 'minimal vapp networking',
        :vapp_networks => [
          {
            :name   => 'network',
            :subnet => [
              {
                :gateway => '1.2.3.4',
                :netmask => '255.255.255.0'
              }
            ]
          }
        ],
        :expect        => lambda do |vapp_net_conf|
          common_vapp_network_config_assertions(vapp_net_conf)
          vapp_net_conf.xpath('./vcloud:NetworkConfig/@networkName').text.must_equal 'network'
          conf = vapp_net_conf.xpath('./vcloud:NetworkConfig/vcloud:Configuration')
          conf.xpath('./vcloud:FenceMode').text.must_equal 'isolated'
          conf.xpath('./vcloud:ParentNetwork').text.must_be_empty
          subnet = conf.xpath('./vcloud:IpScopes/vcloud:IpScope')
          subnet.xpath('./vcloud:Gateway').text.must_equal '1.2.3.4'
          subnet.xpath('./vcloud:Netmask').text.must_equal '255.255.255.0'
        end
      },
      {
        :case          => 'full networking',
        :vapp_networks => [
          {
            :name        => 'network',
            :description => 'VM Network Description',
            :deployed    => true,
            :parent      => 'parent-network-id',
            :fence_mode  => 'bridged',
            :retain      => false,
            :external_ip => '17.17.17.17',
            :subnet      => [
              {
                :enabled    => true,
                :inherited  => false,
                :gateway    => '1.2.3.4',
                :netmask    => '255.255.255.0',
                :dns1       => '5.6.7.8',
                :dns2       => '9.10.11.12',
                :dns_suffix => 'dns-suffix',
                :ip_range   => [{ :start => '192.168.254.100', :end => '192.168.254.199' }]
              }
            ]
          }
        ],
        :expect        => lambda do |vapp_net_conf|
          common_vapp_network_config_assertions(vapp_net_conf)
          vapp_net_conf.xpath('./vcloud:NetworkConfig/@networkName').text.must_equal 'network'
          vapp_net_conf.xpath('./vcloud:NetworkConfig/vcloud:Description').text.must_equal 'VM Network Description'
          vapp_net_conf.xpath('./vcloud:NetworkConfig/vcloud:IsDeployed').text.must_equal 'true'
          conf = vapp_net_conf.xpath('./vcloud:NetworkConfig/vcloud:Configuration')
          conf.xpath('./vcloud:FenceMode').text.must_equal 'bridged'
          conf.xpath('./vcloud:ParentNetwork/@href').text.must_equal 'ENDPOINT/network/parent-network-id'
          conf.xpath('./vcloud:RetainNetInfoAcrossDeployments').text.must_equal 'false'
          conf.xpath('./vcloud:RouterInfo/vcloud:ExternalIp').text.must_equal '17.17.17.17'
          subnet = conf.xpath('./vcloud:IpScopes/vcloud:IpScope')
          subnet.xpath('./vcloud:IsEnabled').text.must_equal 'true'
          subnet.xpath('./vcloud:IsInherited').text.must_equal 'false'
          subnet.xpath('./vcloud:Gateway').text.must_equal '1.2.3.4'
          subnet.xpath('./vcloud:Netmask').text.must_equal '255.255.255.0'
          subnet.xpath('./vcloud:Dns1').text.must_equal '5.6.7.8'
          subnet.xpath('./vcloud:Dns2').text.must_equal '9.10.11.12'
          ip_range = subnet.xpath('./vcloud:IpRanges/vcloud:IpRange')
          ip_range.xpath('./vcloud:StartAddress').text.must_equal '192.168.254.100'
          ip_range.xpath('./vcloud:EndAddress').text.must_equal '192.168.254.199'
        end
      },
      {
        :case          => 'two vapp networks',
        :vapp_networks => [
          {
            :name   => 'network1',
            :subnet => [
              {
                :gateway => '1.1.1.1',
                :netmask => '255.255.255.1'
              }
            ]
          },
          {
            :name   => 'network2',
            :subnet => [
              {
                :gateway => '2.2.2.2',
                :netmask => '255.255.255.2'
              }
            ]
          }
        ],
        :expect        => lambda do |vapp_net_conf|
          common_vapp_network_config_assertions(vapp_net_conf)
          vapp_net_conf.xpath('./vcloud:NetworkConfig').count.must_equal 2
          vapp_net_conf.xpath('./vcloud:NetworkConfig[1]/@networkName').text.must_equal 'network1'
          vapp_net_conf.xpath('./vcloud:NetworkConfig[2]/@networkName').text.must_equal 'network2'
          conf1 = vapp_net_conf.xpath('./vcloud:NetworkConfig[1]/vcloud:Configuration')
          subnet1 = conf1.xpath('./vcloud:IpScopes/vcloud:IpScope')
          subnet1.xpath('./vcloud:Gateway').text.must_equal '1.1.1.1'
          subnet1.xpath('./vcloud:Netmask').text.must_equal '255.255.255.1'
          conf2 = vapp_net_conf.xpath('./vcloud:NetworkConfig[2]/vcloud:Configuration')
          subnet2 = conf2.xpath('./vcloud:IpScopes/vcloud:IpScope')
          subnet2.xpath('./vcloud:Gateway').text.must_equal '2.2.2.2'
          subnet2.xpath('./vcloud:Netmask').text.must_equal '255.255.255.2'
        end
      }
    ].each do |args|
      it args[:case].to_s do
        input = {
          :name          => 'VAPP_NAME',
          :vapp_networks => args[:vapp_networks],
          :endpoint      => 'ENDPOINT'
        }
        output = Fog::VcloudDirector::Generators::Compute::InstantiateVappTemplateParams.new(input).generate_xml
        args[:expect].call(vapp_network_config(Nokogiri::XML(output)))
      end
    end

    def vapp_network_config(xml)
      xml.xpath('//xmlns:NetworkConfigSection')
    end

    def self.common_vapp_network_config_assertions(vapp_net_conf)
      vapp_net_conf.count.must_equal 1
    end
  end

  describe 'Guest customization' do
    [
      {
        :case                => 'hostname',
        :guest_customization => {
          :ComputerName => 'hostname'
        },
        :expect              => lambda do |guest_customization|
          common_guest_customization_assertions(guest_customization)
          hostnames = guest_customization.xpath('./xmlns:ComputerName')
          hostnames.count.must_equal 1
          hostname = hostnames.first
          hostname.text.must_equal 'hostname'
        end
      }
    ].each do |args|
      it args[:case].to_s do
        input = {
          :name       => 'VAPP_NAME',
          :source_vms => [
            {
              :name                => 'VM1',
              :guest_customization => args[:guest_customization]
            }
          ]
        }
        output = Fog::VcloudDirector::Generators::Compute::InstantiateVappTemplateParams.new(input).generate_xml
        args[:expect].call(guest_customization(Nokogiri::XML(output)))
      end
    end

    def guest_customization(xml)
      xml.xpath('//xmlns:SourcedItem/xmlns:InstantiationParams/xmlns:GuestCustomizationSection')
    end

    def self.common_guest_customization_assertions(guest_customization)
      guest_customization.count.must_equal 1
    end
  end

  describe 'NIC connection customization' do
    [
      {
        :case     => 'connect NIC#0 in DHCP mode',
        :networks => [
          {
            :networkName             => 'network',
            :IpAddressAllocationMode => 'DHCP',
            :IsConnected             => true
          }
        ],
        :expect   => lambda do |networks|
          common_networks_assertions(networks)
          network = networks.first
          network.xpath('./@network').text.must_equal 'network'
          network.xpath('./xmlns:NetworkConnectionIndex').text.must_equal '0'
          network.xpath('./xmlns:IpAddressAllocationMode').text.must_equal 'DHCP'
          network.xpath('./xmlns:IpAddress').text.must_be_empty
          network.xpath('./xmlns:IsConnected').text.must_equal 'true'
        end
      },
      {
        :case     => 'connect NIC#0 in MANUAL mode',
        :networks => [
          {
            :networkName             => 'network',
            :IpAddressAllocationMode => 'MANUAL',
            :IpAddress               => '1.2.3.4',
            :IsConnected             => true
          }
        ],
        :expect   => lambda do |networks|
          common_networks_assertions(networks)
          network = networks.first
          network.xpath('./@network').text.must_equal 'network'
          network.xpath('./xmlns:NetworkConnectionIndex').text.must_equal '0'
          network.xpath('./xmlns:IpAddressAllocationMode').text.must_equal 'MANUAL'
          network.xpath('./xmlns:IpAddress').text.must_equal '1.2.3.4'
          network.xpath('./xmlns:IsConnected').text.must_equal 'true'
        end
      },
      {
        :case     => 'connect NIC#0 in POOL mode',
        :networks => [
          {
            :networkName             => 'network',
            :IpAddressAllocationMode => 'POOL',
            :IsConnected             => true
          }
        ],
        :expect   => lambda do |networks|
          common_networks_assertions(networks)
          network = networks.first
          network.xpath('./@network').text.must_equal 'network'
          network.xpath('./xmlns:NetworkConnectionIndex').text.must_equal '0'
          network.xpath('./xmlns:IpAddressAllocationMode').text.must_equal 'POOL'
          network.xpath('./xmlns:IpAddress').text.must_be_empty
          network.xpath('./xmlns:IsConnected').text.must_equal 'true'
        end
      },
      {
        :case     => 'connect NIC#0 and NIC#1',
        :networks => [
          {
            :networkName             => 'network0',
            :IpAddressAllocationMode => 'DHCP',
            :IsConnected             => true
          },
          {
            :networkName             => 'network1',
            :IpAddressAllocationMode => 'MANUAL',
            :IpAddress               => '1.2.3.4',
            :IsConnected             => true
          }
        ],
        :expect   => lambda do |networks|
          networks.count.must_equal 2
          nic0_network = networks[0]
          nic0_network.xpath('./@network').text.must_equal 'network0'
          nic0_network.xpath('./xmlns:NetworkConnectionIndex').text.must_equal '0'
          nic0_network.xpath('./xmlns:IpAddressAllocationMode').text.must_equal 'DHCP'
          nic0_network.xpath('./xmlns:IpAddress').text.must_be_empty
          nic0_network.xpath('./xmlns:IsConnected').text.must_equal 'true'
          nic1_network = networks[1]
          nic1_network.xpath('./@network').text.must_equal 'network1'
          nic1_network.xpath('./xmlns:NetworkConnectionIndex').text.must_equal '1'
          nic1_network.xpath('./xmlns:IpAddressAllocationMode').text.must_equal 'MANUAL'
          nic1_network.xpath('./xmlns:IpAddress').text.must_equal '1.2.3.4'
          nic1_network.xpath('./xmlns:IsConnected').text.must_equal 'true'
        end
      }
    ].each do |args|
      it args[:case].to_s do
        input = {
          :name       => 'VAPP_NAME',
          :source_vms => [
            {
              :name     => 'VM1',
              :networks => args[:networks]
            }
          ]
        }
        output = Fog::VcloudDirector::Generators::Compute::InstantiateVappTemplateParams.new(input).generate_xml
        args[:expect].call(networks(Nokogiri::XML(output)))
      end
    end

    def networks(xml)
      xml.xpath('//xmlns:SourcedItem/xmlns:InstantiationParams/xmlns:NetworkConnectionSection/xmlns:NetworkConnection')
    end

    def self.common_networks_assertions(networks)
      networks.count.must_equal 1
    end
  end
end
