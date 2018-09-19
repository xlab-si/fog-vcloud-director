module Fog
  module VcloudDirector
    class Compute

      class CustomField < Model

        identity  :id
        attribute :value
        attribute :type
        attribute :password
        attribute :user_configurable

      end
    end
  end
end
