# -*- encoding: utf-8 -*-
require File.expand_path('../lib/polytaggable/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michael Baumgarten"]
  gem.email         = ["mbaumgarten@iberon.com"]
  gem.description   = %q{Tagging implementation}
  gem.summary       = %q{You can specify the tagger through a polymorphic association.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "polytaggable"
  gem.require_paths = ["lib"]
  gem.version       = Polytaggable::VERSION

end

