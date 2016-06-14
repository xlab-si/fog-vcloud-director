ENV['FOG_RC']         = ENV['FOG_RC'] || File.expand_path('../.fog', __FILE__)
ENV['FOG_CREDENTIAL'] = ENV['FOG_CREDENTIAL'] || 'default'

require 'fog/vcloud_director'
# require 'fog/bin' # for available_providers and registered_providers
# require 'ostruct'

Excon.defaults.merge!(:debug_request => true, :debug_response => true)

require File.expand_path(File.join(File.dirname(__FILE__), 'helpers', 'mock_helper'))

# This overrides the default 600 seconds timeout during live test runs
if Fog.mocking?
  FOG_TESTING_TIMEOUT = ENV['FOG_TEST_TIMEOUT'] || 2000
  Fog.timeout = 2000
  Fog::Logger.warning "Setting default fog timeout to #{Fog.timeout} seconds"

  # These sets of tests do not behave nicely when running mocked tests
  Thread.current[:tags] << '-xenserver'
  Thread.current[:tags] << '-joyent'
  Thread.current[:tags] << '-dreamhost'
else
  FOG_TESTING_TIMEOUT = Fog.timeout
end

def lorem_file
  File.open(File.dirname(__FILE__) + '/lorem.txt', 'r')
end

def array_differences(array_a, array_b)
  (array_a - array_b) | (array_b - array_a)
end
