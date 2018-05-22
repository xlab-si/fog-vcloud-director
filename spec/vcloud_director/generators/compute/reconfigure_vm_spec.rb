require './spec/spec_helper.rb'

describe Fog::Generators::Compute::VcloudDirector::ReconfigureVm do
  let(:current)  { Nokogiri::XML(File.read('./spec/fixtures/vm.xml')) }
  let(:hardware) { {} }
  let(:networks) { nic_conf.empty? ? [] : [nic_conf] }
  let(:nic_conf) { {} }
  let(:output)   { Nokogiri::XML(Fog::Generators::Compute::VcloudDirector::ReconfigureVm.generate_xml(current, input)) }
  let(:input) do
    input = {}
    input[:hardware] = hardware unless hardware.empty?
    input[:networks] = networks unless networks.empty?
    input
  end

  describe 'reconfigure hardware' do
    describe 'name' do
      let(:input) { { :name => 'new name' } }

      it 'name' do
        output.xpath('/*/@name').first.value.must_equal 'new name'
      end
    end

    describe 'description' do
      let(:input) { { :description => 'new description' } }

      it 'description' do
        output.at('Description').content.must_equal 'new description'
      end
    end

    describe 'memory' do
      let(:hardware) { { :memory => { :quantity_mb => 123 } } }

      it 'memory' do
        mem = output.xpath("//ovf:VirtualHardwareSection/ovf:Item[./rasd:ResourceType = '4']")
        mem.xpath('./rasd:VirtualQuantity').text.must_equal '123'
      end
    end

    describe 'cpu' do
      let(:hardware) { { :cpu => { :num_cores => 8, :cores_per_socket => 4 } } }

      it 'cpu' do
        cpu = output.xpath("//ovf:VirtualHardwareSection/ovf:Item[./rasd:ResourceType = '3']")
        cpu.xpath('./rasd:VirtualQuantity').text.must_equal '8'
        cpu.xpath('./vmw:CoresPerSocket').text.must_equal '4'
      end
    end

    describe 'disk' do
      let(:hardware) { { :disk => disks } }

      describe 'resize' do
        let(:disks) { { :id => '2000', :capacity_mb => 123 } }

        it 'resize' do
          all_disks(output).count.must_equal 3
          disk_by_id(output, '2000').at('./rasd:HostResource')['ns13:capacity'].must_equal '123'
        end
      end

      describe 'resize nonexisting' do
        let(:disks) { { :id => 'nonexisting', :capacity_mb => 123 } }

        it 'resize nonexisting' do
          -> { output }.must_raise Fog::Compute::VcloudDirector::PreProcessingError
        end
      end

      describe 'remove' do
        let(:disks) { { :id => '2000', :capacity_mb => -1 } }

        it 'remove' do
          all_disks(output).count.must_equal 2
          disk_by_id(output, '2000').must_be_empty
        end
      end

      describe 'remove nonexisting' do
        let(:disks) { { :id => 'nonexisting', :capacity_mb => -1 } }

        it 'remove nonexisting' do
          all_disks(output).count.must_equal 3
        end
      end

      describe 'add' do
        let(:disks) { { :capacity_mb => 123 } }

        it 'add' do
          all_disks(output).count.must_equal 4
          all_disks(output).last.at('./rasd:HostResource')['ns13:capacity'].must_equal '123'
        end
      end

      describe 'resize, remove and add' do
        let(:disks) do
          [
            { :id => '2000', :capacity_mb => 123 },
            { :id => '2001', :capacity_mb => -1 },
            { :capacity_mb => 321 }
          ]
        end

        it 'resize, remove and add' do
          all_disks(output).count.must_equal 3
          disk_by_id(output, '2000').at('./rasd:HostResource')['ns13:capacity'].must_equal '123'
          disk_by_id(output, '2001').must_be_empty
          all_disks(output).last.at('./rasd:HostResource')['ns13:capacity'].must_equal '321'
        end
      end

      def all_disks(xml)
        xml.xpath("//ovf:VirtualHardwareSection/ovf:Item[./rasd:ResourceType = '17']")
      end

      def disk_by_id(xml, id)
        all_disks(xml).xpath("//ovf:Item[./rasd:InstanceID = '#{id}']")
      end
    end
  end

  describe 'reconfigure NICs' do
    describe 'update NIC' do
      describe 'update NIC - truthful values' do
        let(:nic_conf) do
          {
            :idx       => 0,
            :name      => 'vApp net name',
            :mac       => '11:22:33:44:55:66',
            :needs     => true,
            :ip        => '1.2.3.4',
            :connected => true,
            :mode      => 'MANUAL',
            :type      => 'adapter type'
          }
        end

        it 'update NIC' do
          assert_nic_count(output, 2)
          assert_nic(
            output,
            0,
            :name      => 'vApp net name',
            :mac       => '11:22:33:44:55:66',
            :needs     => true,
            :ip        => '1.2.3.4',
            :connected => true,
            :mode      => 'MANUAL',
            :type      => 'adapter type'
          )
        end
      end

      describe 'update NIC - falseful values' do
        let(:nic_conf) do
          {
            :idx       => 0,
            :name      => 'vApp net name',
            :mac       => '11:22:33:44:55:66',
            :needs     => false,
            :ip        => '',
            :connected => false,
            :mode      => 'MANUAL',
            :type      => 'adapter type'
          }
        end

        it 'update NIC - falseful values' do
          assert_nic_count(output, 2)
          assert_nic(
            output,
            0,
            :name      => 'vApp net name',
            :mac       => '11:22:33:44:55:66',
            :needs     => false,
            :ip        => '',
            :connected => false,
            :mode      => 'MANUAL',
            :type      => 'adapter type'
          )
        end
      end
    end

    describe 'remove NIC' do
      let(:nic_conf) { { :idx => 1, :new_idx => -1 } }

      it 'remove NIC' do
        assert_nic_count(output, 1)
        output.xpath("//xmlns:NetworkConnection[xmlns:NetworkConnectionIndex = '1']").must_be_empty
      end
    end

    describe 'add NIC' do
      describe 'add NIC - truthful values' do
        let(:nic_conf) do
          {
            :idx       => nil,
            :new_idx   => '5',
            :name      => 'vApp net name',
            :mac       => '11:22:33:44:55:66',
            :needs     => true,
            :ip        => '1.2.3.4',
            :connected => true,
            :mode      => 'MANUAL',
            :type      => 'adapter type'
          }
        end

        it 'add NIC' do
          assert_nic_count(output, 3)
          assert_nic(
            output,
            5,
            :name      => 'vApp net name',
            :mac       => '11:22:33:44:55:66',
            :needs     => true,
            :ip        => '1.2.3.4',
            :connected => true,
            :mode      => 'MANUAL',
            :type      => 'adapter type'
          )
        end
      end

      describe 'add NIC - falseful values' do
        let(:nic_conf) do
          {
            :idx       => nil,
            :new_idx   => '5',
            :name      => 'vApp net name',
            :mac       => '11:22:33:44:55:66',
            :needs     => false,
            :ip        => '',
            :connected => false,
            :mode      => 'MANUAL',
            :type      => 'adapter type'
          }
        end

        it 'add NIC - falseful values' do
          assert_nic_count(output, 3)
          assert_nic(
            output,
            5,
            :name      => 'vApp net name',
            :mac       => '11:22:33:44:55:66',
            :needs     => false,
            :ip        => '',
            :connected => false,
            :mode      => 'MANUAL',
            :type      => 'adapter type'
          )
        end
      end

      describe 'add first NIC' do
        let(:networks) do
          [
            {
              :idx     => 0,
              :new_idx => -1
            },
            {
              :idx     => 1,
              :new_idx => -1
            },
            {
              :idx     => nil,
              :new_idx => 2
            }
          ]
        end

        it 'add first NIC' do
          assert_nic_count(output, 1)
        end
      end
    end

    describe 'set primary NIC' do
      describe 'regular' do
        let(:nic_conf) { { :idx => 1, :primary => true } }

        it 'set primary NIC - regular' do
          output.xpath("//xmlns:NetworkConnectionSection/xmlns:PrimaryNetworkConnectionIndex").text.must_equal '1'
        end
      end

      describe 'when updating idx' do
        let(:nic_conf) { { :idx => 1, :new_idx => 5, :primary => true } }

        it 'set primary NIC - when updating idx' do
          assert_nic_count(output, 2)
          output.xpath("//xmlns:NetworkConnectionSection/xmlns:PrimaryNetworkConnectionIndex").text.must_equal '5'
        end
      end

      describe 'new NIC' do
        let(:nic_conf) { { :idx => nil, :new_idx => 3, :primary => true } }

        it 'set primary NIC - new NIC' do
          assert_nic_count(output, 3)
          output.xpath("//xmlns:NetworkConnectionSection/xmlns:PrimaryNetworkConnectionIndex").text.must_equal '3'
        end
      end
    end

    describe 'when VM has no NICs yet' do
      let(:current) { Nokogiri::XML(File.read('./spec/fixtures/empty_vm.xml')) }

      describe 'when VM has no NICs yet - add NIC' do
        let(:nic_conf) do
          {
            :idx       => nil,
            :new_idx   => '5',
            :name      => 'vApp net name',
            :mac       => '11:22:33:44:55:66',
            :needs     => true,
            :ip        => '1.2.3.4',
            :connected => true,
            :mode      => 'MANUAL',
            :type      => 'adapter type'
          }
        end

        it 'when VM has no NICs yet - add NIC' do
          assert_nic_count(output, 1)
          assert_nic(
            output,
            5,
            :name      => 'vApp net name',
            :mac       => '11:22:33:44:55:66',
            :needs     => true,
            :ip        => '1.2.3.4',
            :connected => true,
            :mode      => 'MANUAL',
            :type      => 'adapter type'
          )
        end
      end

      describe 'set primary NIC' do
        let(:nic_conf) { { :idx => nil, :new_idx => 3, :primary => true } }

        it 'set primary NIC - new NIC' do
          assert_nic_count(output, 1)
          output.xpath("//xmlns:NetworkConnectionSection/xmlns:PrimaryNetworkConnectionIndex").text.must_equal '3'
        end
      end
    end

    def assert_nic_count(xml, n)
      xml.xpath("//xmlns:NetworkConnection/xmlns:NetworkConnectionIndex").size.must_equal n
      asset_network_connection_section_ordered(xml, :num_nic => n)
    end

    def assert_nic(xml, idx, name: nil, mac: nil, ip: nil, connected: nil, mode: nil, type: nil, needs: nil)
      nic = xml.xpath("//xmlns:NetworkConnection[xmlns:NetworkConnectionIndex = '#{idx}']")
      nic.xpath('./@network').first.value.must_equal name
      nic.xpath('./@needsCustomization').first.value.must_equal needs.to_s
      nic.xpath('./xmlns:MACAddress').text.must_equal mac
      nic.xpath('./xmlns:IpAddress').text.must_equal ip
      nic.xpath('./xmlns:IsConnected').text.must_equal connected.to_s
      nic.xpath('./xmlns:NetworkAdapterType').text.must_equal type
      nic.xpath('./xmlns:IpAddressAllocationMode').text.must_equal mode

      asset_network_connection_ordered(nic)
    end

    def asset_network_connection_section_ordered(xml, num_nic: 2)
      children = xml.xpath('//xmlns:NetworkConnectionSection').children.select(&:element?).map(&:name)
      order = (%w(Info PrimaryNetworkConnectionIndex) + Array.new(num_nic, 'NetworkConnection') + %w(Link)).select do |el|
        children.include?(el)
      end
      children.must_equal order
    end

    def asset_network_connection_ordered(xml)
      children = xml.children.select(&:element?).map(&:name)
      order = %w(NetworkConnectionIndex IpAddress ExternalIpAddress IsConnected MACAddress IpAddressAllocationMode NetworkAdapterType).select do |el|
        children.include?(el)
      end
      children.must_equal order
    end
  end
end
