# Use ruby 2.5.0 with default gemset
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "has_meta/version"

Gem::Specification.new do |spec|
  spec.name          = "has-meta"
  spec.version       = HasMeta::VERSION
  spec.authors       = ["Dan Drust"]
  spec.email         = ["dan.drust@protrainings.com"]

  spec.summary       = "Create key/value store for relational databases"
  spec.homepage      = 'http://git.procpr.org/dan.drust/has-meta.git'
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

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
  
  # spec.add_development_dependency 'mysql2', '~> 0.3'
  # spec.add_development_dependency 'pg'

end
