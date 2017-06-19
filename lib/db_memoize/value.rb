require 'active_record/metal'

module DbMemoize
  class Value < ActiveRecord::Base
    self.table_name = 'memoized_values'

    include ActiveRecord::Metal
  end
end
