# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'db_memoize/version'

Gem::Specification.new do |spec|
  spec.name          = "db_memoize"
  spec.version       = DbMemoize::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ["johannes-kostas goetzinger"]
  spec.email         = ["goetzinger@mediapeers.com"]

  spec.summary       = %q{library to cache (memoize) method return values in database}
  spec.description   = %q{library to cache (memoize) method return values in database}
  spec.homepage      = "https://github.com/mediapeers/db_memoize"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'simple-sql', '>= 0.4.20', '~> 0'
  spec.add_development_dependency 'railties', '~> 4.2'
  spec.add_development_dependency 'activerecord', '~> 4.2.10'

  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'pg', '~> 0.20'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'simplecov', '~> 0.16'
  spec.add_development_dependency 'rubocop', '~> 0.59.2'
  spec.add_development_dependency 'database_cleaner', '~> 1.5.3'
  spec.add_development_dependency 'factory_girl', '~> 4.7.0'
  spec.add_development_dependency 'gem-release'
end
