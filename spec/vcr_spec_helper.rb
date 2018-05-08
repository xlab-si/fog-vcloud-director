require './spec/spec_helper'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.allow_http_connections_when_no_cassette = false
  config.hook_into :webmock
  config.default_cassette_options = { :allow_unused_http_interactions => false }
end

def vcr_service
  hostname = secrets.fetch(:hostname, 'hostname')
  username = secrets.fetch(:username, 'username')
  password = secrets.fetch(:password, 'password')

  VCR.configure do |config|
    config.before_playback { |interaction| interaction.filter!('VMWARE_CLOUD_HOST', hostname) }
    config.filter_sensitive_data('VMWARE_CLOUD_AUTHORIZATION') { Base64.encode64("#{username}:#{password}").chomp }
    config.filter_sensitive_data('VMWARE_CLOUD_HOST') { hostname }
  end

  @vcr_service ||= VCR.use_cassette('authentication') do
    Fog::Compute::VcloudDirector.new(
      :vcloud_director_username      => username,
      :vcloud_director_password      => password,
      :vcloud_director_host          => hostname,
      :vcloud_director_show_progress => false,
      :vcloud_director_api_version   => '9.0',
      :connection_options            => { :ssl_verify_peer => false }
    ).tap { |service| service.send(:login) }
  end
end
