# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fog/vcloud_director/version"

Gem::Specification.new do |spec|
  spec.name          = "fog-vcloud-director"
  spec.version       = Fog::VcloudDirector::VERSION
  spec.authors       = ["Luka Zakrajšek"]
  spec.email         = ["luka@bancek.net"]
  spec.summary       = "Module for the 'fog' gem to support vCloud Director."
  spec.description   = 'This library can be used as a module for `fog` or as standalone provider
                        to use the vCloud Director in applications.'
  spec.homepage      = "https://github.com/xlab-si/fog-vcloud-director"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.0"

  spec.add_dependency "fog-core", ">= 1.40" # tested on 1.40 and 2.1.0
  spec.add_dependency "fog-xml"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "shindo"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "rubocop", "~>0.52.1"
  spec.add_development_dependency "pronto-rubocop"
end
