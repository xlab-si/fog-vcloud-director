require './spec/vcr_spec_helper.rb'

describe '.get_vms' do
  it 'get_vms' do
    VCR.use_cassette('get_vms') do
      response = vcr_service.get_vms('vapp-fe8d013d-dd2f-4ac6-9e8a-3a4a18e0a62e')
      response.status.must_equal 200
      response.body[:vms].size.must_equal 2
    end
  end
end
