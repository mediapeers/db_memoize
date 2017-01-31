module DbMemoize
  # The Helpers module contains some helper methods, mostly to not pollute
  # the namespace of memoized objects and classes.
  module Helpers
    module_function

    def find_ids(records_or_ids)
      records_or_ids = Array(records_or_ids)
      return [] if records_or_ids.empty?

      records_or_ids.first.is_a?(ActiveRecord::Base) ? records_or_ids.map(&:id) : records_or_ids
    end

    def log(model, method_name, msg)
      DbMemoize.logger.send(DbMemoize.log_level, "DbMemoize <#{model.class.name} id: #{model.id}>##{method_name} - #{msg}")
    end
  end
end
