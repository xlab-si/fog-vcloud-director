require './spec/spec_helper.rb'

describe Fog::Generators::Compute::VcloudDirector::ReconfigureVm do
  let(:current)  { Nokogiri::XML(File.read('./spec/fixtures/vm.xml')) }
  let(:hardware) { {} }
  let(:input)    { hardware ? { :hardware => hardware } : {} }
  let(:output)   { Nokogiri::XML(Fog::Generators::Compute::VcloudDirector::ReconfigureVm.generate_xml(current, input)) }

  describe 'reconfigure' do
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
end
