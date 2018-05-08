require 'pp'
require 'securerandom'

require 'fog/core'
require 'fog/core/model'
require 'fog/core/collection'
require 'fog/xml'
require 'fog/vcloud_director/core'
require 'fog/vcloud_director/query'
require 'fog/vcloud_director/compute'

Dir['./lib/fog/vcloud_director/generators/**/*.rb'].each {|file| require file }
Dir['./lib/fog/vcloud_director/models/**/*.rb'].each {|file| require file }
Dir['./lib/fog/vcloud_director/parsers/**/*.rb'].each {|file| require file }
Dir['./lib/fog/vcloud_director/requests/**/*.rb'].each {|file| require file }
