# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'inherit-ar-nevermore/version'

Gem::Specification.new do |gem|
  gem.name          = "inherit-ar-nevermore"
  gem.version       = Inherit::Ar::Nevermore::VERSION
  gem.authors       = ["Emilio Gutter"]
  gem.email         = ["egutter@10pines.com"]
  gem.description   = %q{Replace ActiveRecord inheritance with a persistence API module}
  gem.summary       = %q{Replace ActiveRecord inheritance with a persistence API module. Run test faster using an in-memory implementation of the persistence API}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "sqlite3-ruby"
  gem.add_runtime_dependency(%q<activesupport>, [">= 3.0"])
  gem.add_runtime_dependency(%q<activerecord>, [">= 3.0"])
  gem.add_runtime_dependency(%q<actionpack>, [">= 3.0"])
  gem.add_runtime_dependency(%q<railties>, [">= 3.0"])
end
