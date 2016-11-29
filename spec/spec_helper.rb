$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "db_memoize"
require 'active_record'
require 'ffaker'
require 'pry'
require 'awesome_print'
require 'database_cleaner'
require 'factory_girl'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.dirname(__FILE__) + '/schema.rb'

unless ENV['SKIP_COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    minimum_coverage 98
  end
end

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    FactoryGirl.find_definitions
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
