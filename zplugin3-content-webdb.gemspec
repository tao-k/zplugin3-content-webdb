$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "zplugin3/content/webdb/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "zplugin3-content-webdb"
  s.version     = Zplugin3::Content::Webdb::VERSION
  s.authors     = [""]
  s.email       = [""]
  s.homepage    = "https://github.com/tao-k/zplugin3-content-webdb"
  s.summary     = "CustomField Content for ZOMEKIv3"
  s.description = "Add Costum Field Database to ZOMEKI v3"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", '5.0.0.1'
  s.add_dependency 'will_paginate', '~> 3.1.3'

  s.add_dependency 'delayed_job', '~> 4.1.3'
  s.add_dependency 'delayed_job_active_record', '~> 4.1.2'
  s.add_dependency 'delayed_job_master', '~> 1.1.0'

  s.add_dependency "pg"
end
