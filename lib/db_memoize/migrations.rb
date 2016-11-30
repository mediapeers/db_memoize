module DbMemoize
  class Migrations
    class << self
      def create_tables(migration)
        migration.create_table :memoized_values, id: false do |t|
          t.string :entity_type
          t.string :entity_id
          t.string :method_name
          t.string :arguments_hash
          t.string :custom_key
          t.text :value
          t.datetime :created_at
        end

        migration.add_index :memoized_values, [:entity_type, :entity_id]
      end
    end
  end
end
