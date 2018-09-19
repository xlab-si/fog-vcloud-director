require "minitest/autorun"
require "minitest/spec"
require "minitest/unit"
require "mocha/minitest"
require "yaml"

$LOAD_PATH.unshift "lib"

require "fog/vcloud_director"
require "./spec/common_assertions"

include Fog::VcloudDirector::Generators::Compute::ComposeCommon

def secrets
  @secrets ||= File.file?(secrets_path) ? YAML.load_file(secrets_path) : {}
end

def secrets_path
  'spec/secrets.yaml'
end
