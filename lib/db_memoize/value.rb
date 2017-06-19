module DbMemoize
  class Value < ActiveRecord::Base
    self.table_name = 'memoized_values'

    include DbMemoize::Metal
  end
end
