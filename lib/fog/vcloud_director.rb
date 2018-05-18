require 'pp'
require 'securerandom'

require 'fog/core'
require 'fog/core/model'
require 'fog/core/collection'
require 'fog/xml'
require 'fog/vcloud_director/core'
require 'fog/vcloud_director/query'
require 'fog/vcloud_director/compute'

Dir[File.join(File.dirname(__FILE__), 'vcloud_director', 'generators', '**', '*.rb')].sort.each {|file| require file }
Dir[File.join(File.dirname(__FILE__), 'vcloud_director', 'models', '**', '*.rb')].sort.each {|file| require file }
Dir[File.join(File.dirname(__FILE__), 'vcloud_director', 'parsers', '**', '*.rb')].sort.each {|file| require file }
Dir[File.join(File.dirname(__FILE__), 'vcloud_director', 'requests', '**', '*.rb')].sort.each {|file| require file }
