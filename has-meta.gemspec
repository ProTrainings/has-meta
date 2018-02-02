# Use ruby 2.5.0 with default gemset
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "has_meta/version"

Gem::Specification.new do |spec|
  spec.name          = "has-meta"
  spec.version       = HasMeta::VERSION
  spec.authors       = ["Dan Drust"]
  spec.email         = ["dan.drust@protrainings.com"]

  spec.summary       = "A key/value store solution for Rails apps with bloated tables"
  spec.homepage      = 'https://www.github.com/protrainings/has-meta'
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  
  spec.add_dependency 'activerecord', ['>= 4.2.8']

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rspec-rails'
end
