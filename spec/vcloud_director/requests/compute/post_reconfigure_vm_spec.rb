require './spec/vcr_spec_helper.rb'

describe '.post_reconfigure_vm' do
  let(:current) { Nokogiri::XML(File.read('./spec/fixtures/vm.xml')) }
  let(:options) do
    {
      :description => 'the new description',
      :hardware    => {
        :memory => { :quantity_mb => 4096 },
        :cpu    => { :num_cores => 8, :cores_per_socket => 4 },
        :disk   => [
          { :id => '2000', :capacity_mb => 5 * 1024 },
          { :id => '2001', :capacity_mb => -1 },
          { :capacity_mb => 8 * 1024 }
        ]
      }
    }
  end

  it 'virtual hardware' do
    VCR.use_cassette('post_reconfigure_vm-virtual_hardware') do
      response = vcr_service.post_reconfigure_vm('vm-8dc9990c-a55a-418e-8e21-5942a20b93ef', current, options)
      response.status.must_equal 202
    end
  end
end
