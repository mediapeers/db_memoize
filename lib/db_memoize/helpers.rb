module DbMemoize
  # The Helpers module contains some helper methods, mostly to not pollute
  # the namespace of memoized objects and classes.
  module Helpers
    extend self

    def find_ids(records_or_ids)
      records_or_ids = Array(records_or_ids)
      return [] if records_or_ids.empty?

      records_or_ids.first.is_a?(ActiveRecord::Base) ? records_or_ids.map(&:id) : records_or_ids
    end
  end
end
