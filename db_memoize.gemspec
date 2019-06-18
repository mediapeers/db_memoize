Gem::Specification.new do |spec|
  spec.name          = "db_memoize"
  spec.version       = File.read("VERSION")
  spec.licenses      = ['MIT']
  spec.authors       = ["johannes-kostas goetzinger"]
  spec.email         = ["goetzinger@mediapeers.com"]

  spec.summary       = %q{library to cache (memoize) method return values in database}
  spec.description   = %q{library to cache (memoize) method return values in database}
  spec.homepage      = "https://github.com/mediapeers/db_memoize"

  gem.files = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR).select do |file|
    file.match(%r{^(lib/|VERSION|LICENSE|README)})
  end

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
end
