require 'active_record'
require 'active_support'
require 'digest'
require 'benchmark'
require 'db_memoize/version'
require 'db_memoize/value'
require 'db_memoize/helpers'
require 'db_memoize/model'
require 'db_memoize/railtie' if defined?(Rails)

module DbMemoize
  class << self
    attr_writer :logger, :log_level

    def logger
      @logger ||= ::Logger.new(STDOUT)
    end

    def log_level
      @log_level ||= :debug
    end
  end
end
