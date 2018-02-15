require './spec/vcloud_director/spec_helper.rb'
require 'minitest/autorun'
require 'nokogiri'
require './lib/fog/vcloud_director/generators/compute/instantiate_vapp_template_params.rb'

describe Fog::Generators::Compute::VcloudDirector::InstantiateVappTemplateParams do
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

      output = Fog::Generators::Compute::VcloudDirector::InstantiateVappTemplateParams.new(params).generate_xml
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
        output = Fog::Generators::Compute::VcloudDirector::InstantiateVappTemplateParams.new(input).generate_xml
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
end
