require './spec/vcr_spec_helper.rb'

describe '.get_vdc' do
  it 'get_vdc' do
    VCR.use_cassette('get_vdc') do
      response = vcr_service.get_vdc('cf6ea964-a67f-4ba1-b69e-3dd5d6cb0c89')
      response.status.must_equal 200
    end
  end
end
