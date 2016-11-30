require 'active_record'
require 'active_support'
require 'digest'
require 'db_memoize/version'
require 'db_memoize/value'
require 'db_memoize/model'

module DbMemoize
  class << self
    attr_accessor :default_custom_key
  end
end
