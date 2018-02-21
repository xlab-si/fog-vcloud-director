require './spec/vcloud_director/spec_helper.rb'
require 'minitest/autorun'
require 'nokogiri'
require './lib/fog/vcloud_director/generators/compute/compose_common.rb'

include Fog::Generators::Compute::VcloudDirector::ComposeCommon

describe Fog::Generators::Compute::VcloudDirector::ComposeCommon do
  describe '.calculate_fence_mode' do
    [
      {
        :case        => 'default',
        :mode        => nil,
        :parent      => nil,
        :parent_name => nil,
        :expected    => 'isolated'
      },
      {
        :case        => 'prevent isolated when parent',
        :mode        => 'isolated',
        :parent      => 'parent-id',
        :parent_name => nil,
        :expected    => 'bridged'
      },
      {
        :case        => 'keep natRouted when parent',
        :mode        => 'natRouted',
        :parent      => 'parent-id',
        :parent_name => nil,
        :expected    => 'natRouted'
      },
      {
        :case        => 'keep bridged when parent',
        :mode        => 'bridged',
        :parent      => 'parent-id',
        :parent_name => nil,
        :expected    => 'bridged'
      },
      {
        :case        => 'prevent bridged when no parent',
        :mode        => 'bridged',
        :parent      => nil,
        :parent_name => nil,
        :expected    => 'isolated'
      },
      {
        :case        => 'prevent natRouted when no parent',
        :mode        => 'natRouted',
        :parent      => nil,
        :parent_name => nil,
        :expected    => 'isolated'
      },
      {
        :case        => 'prevent isolated when parent_name',
        :mode        => 'isolated',
        :parent      => nil,
        :parent_name => 'parent-name',
        :expected    => 'bridged'
      },
    ].each do |args|
      it args[:case].to_s do
        mode = Fog::Generators::Compute::VcloudDirector::ComposeCommon.send(
          :calculate_fence_mode,
          args[:mode],
          args[:parent],
          args[:parent_name]
        )
        mode.must_equal(args[:expected])
      end
    end
  end
end
