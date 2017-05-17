$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'active_record'
require 'pry'
require 'awesome_print'
require 'database_cleaner'
require 'factory_girl'

unless ENV['SKIP_COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    minimum_coverage 98
  end
end

require "db_memoize"
require './spec/support/bicycle'

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "db_memoize_test"

DbMemoize.logger = Logger.new("log/test.log")

load File.dirname(__FILE__) + '/schema.rb'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.run_all_when_everything_filtered = true
  config.filter_run focus: (ENV['CI'] != 'true')

  config.before(:suite) do
    FactoryGirl.lint
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
