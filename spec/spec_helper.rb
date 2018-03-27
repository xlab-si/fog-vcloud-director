require "minitest/autorun"
require "minitest/spec"
require "minitest/unit"
require "mocha/minitest"

$LOAD_PATH.unshift "lib"

require "fog/vcloud_director"

include Fog::Generators::Compute::VcloudDirector::ComposeCommon
