require 'db_memoize/migrations'

ActiveRecord::Schema.define do
  self.verbose = false

  connection = ActiveRecord::Base.connection

  if connection.tables.include?('db_memoize.memoized_values')
    connection.execute 'DELETE FROM db_memoize.memoized_values'
  else
    DbMemoize::Migrations.create_tables(self)
  end

  if connection.tables.include?('bicycles')
    connection.execute 'DELETE FROM bicycles'
  else
    create_table :bicycles, force: true do |t|
      t.string :name
      t.timestamps null: false
    end
  end
end
