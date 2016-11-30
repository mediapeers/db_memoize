module DbMemoize
  class Value < ActiveRecord::Base
    self.table_name = 'memoized_values'
    belongs_to :entity, polymorphic: true
  end
end
