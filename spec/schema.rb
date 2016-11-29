require 'db_memoize/migrations'

ActiveRecord::Schema.define do
  self.verbose = false
  DbMemoize::Migrations.create_memoized_values_table(self)
end
