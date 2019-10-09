Gem::Specification.new do |spec|
  spec.name          = "db_memoize"
  spec.version       = File.read("VERSION")
  spec.licenses      = ['MIT']
  spec.authors       = ["johannes-kostas goetzinger"]
  spec.email         = ["goetzinger@mediapeers.com"]

  spec.summary       = %q{library to cache (memoize) method return values in database}
  spec.description   = %q{library to cache (memoize) method return values in database}
  spec.homepage      = "https://github.com/mediapeers/db_memoize"

  spec.files         = `git ls-files`.split("\n").grep(%r{^(lib/|VERSION|LICENSE|README)})
  spec.require_paths = ['lib']

  spec.add_dependency 'simple-sql', '~> 0.5.23'

  spec.add_development_dependency 'railties',     '> 4.2'
  spec.add_development_dependency 'activerecord', '> 4.2'
  spec.add_development_dependency 'rake',         '~> 12.0'
  spec.add_development_dependency 'pg',           '~> 0.20'

  spec.add_development_dependency 'rspec',            '~> 3.8'
  spec.add_development_dependency 'simplecov',        '~> 0.17'
  spec.add_development_dependency 'rubocop',          '~> 0.59.2'
  spec.add_development_dependency 'database_cleaner', '~> 1.5.3'
  spec.add_development_dependency 'factory_bot',      '~> 4.10.0'
end
