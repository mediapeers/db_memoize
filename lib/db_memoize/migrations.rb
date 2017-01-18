module DbMemoize
  class Migrations
    class << self
      def create_tables(migration)
        migration.create_table :memoized_values, id: false do |t|
          t.string :entity_table_name
          t.integer :entity_id
          t.string :method_name
          t.string :arguments_hash
          t.string :custom_key
          t.binary :value
          t.datetime :created_at
        end

        migration.add_index :memoized_values, [:entity_table_name, :entity_id]
      end
    end
  end
end
