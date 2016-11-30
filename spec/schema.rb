require 'db_memoize/migrations'

ActiveRecord::Schema.define do
  self.verbose = false
  DbMemoize::Migrations.create_tables(self)

  create_table :bicycles, force: true do |t|
    t.string :name
    t.timestamps null: false
  end
end
