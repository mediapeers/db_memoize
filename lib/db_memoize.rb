require 'active_record'
require 'digest'
require 'db_memoize/version'
require 'db_memoize/value'

module DbMemoize
  class << self
    attr_accessor :default_custom_key
  end
end
