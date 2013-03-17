# -*- encoding: utf-8 -*-
require File.expand_path('../lib/em-dextras/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rafael de F. Ferreira"]
  gem.email         = ["public@rafaelferreira.net"]
  gem.description   = %q{Utilities to help working with EventMachine deferrables.}
  gem.summary       = %q{ Utilities to help working with EventMachine Deferrables. Includes probes for asynchronous tests and a DSL to chain deferrables.  }
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "em-dextras"
  gem.require_paths = ["lib"]
  gem.version       = Em::Dextras::VERSION

  gem.add_runtime_dependency("eventmachine", [">= 0.12.10"])
  gem.add_development_dependency("rspec")

  gem.add_development_dependency("guard")
  gem.add_development_dependency("guard-rspec")
  gem.add_development_dependency("rb-inotify")
end
