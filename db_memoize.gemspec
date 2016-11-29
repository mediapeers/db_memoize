# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'db_memoize/version'

Gem::Specification.new do |spec|
  spec.name          = "db_memoize"
  spec.version       = DbMemoize::VERSION
  spec.authors       = ["johannes-kostas goetzinger"]
  spec.email         = ["goetzinger@mediapeers.com"]

  spec.summary       = %q{library to cache (memoize) method return values in database}
  spec.description   = %q{library to cache (memoize) method return values in database}
  spec.homepage      = "https://github.com/mediapeers/db_memoize"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'railties', '~> 4.2'
  spec.add_development_dependency 'activemodel', '~> 4.2'
  spec.add_development_dependency 'actionpack', '~> 4.2'
  spec.add_development_dependency 'activesupport', '~> 4.2'
  spec.add_development_dependency 'activerecord', '~> 4.2'
  spec.add_development_dependency 'activejob', '~> 4.2'
  spec.add_development_dependency 'arel', '6.0.0'
  spec.add_development_dependency 'rake', '~> 10.5'
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency 'rspec-rails', '~> 3.4'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'pry-byebug', '~> 2.0'
  spec.add_development_dependency 'yard', '~> 0'
  spec.add_development_dependency 'simplecov', '~> 0.7.1'
  spec.add_development_dependency 'rubocop', '~> 0.37.2'
  spec.add_development_dependency 'database_cleaner', '~> 1.5.3'
  spec.add_development_dependency 'factory_girl', '~> 4.7.0'
  spec.add_development_dependency 'ffaker'
  spec.add_development_dependency 'awesome_print'
end
