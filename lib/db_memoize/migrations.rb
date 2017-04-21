module DbMemoize
  class Migrations
    class << self
      def create_tables(migration)
        migration.create_table :memoized_values, id: false do |t|
          t.string :entity_table_name
          t.integer :entity_id
          t.string :method_name
          t.string :arguments_hash
          t.binary :value
          t.datetime :created_at
        end

        migration.add_index :memoized_values, [:entity_table_name, :entity_id]
        migrate_empty_arguments_support(migration)
      end

      def migrate_empty_arguments_support(migration)
        # entity_id/entity_table_name should have a better chance to be useful, since
        # there is more variance in entity_ids than there is in entity_table_names.
        migration.remove_index :memoized_values, [:entity_table_name, :entity_id]
        migration.add_index :memoized_values, [:entity_id, :entity_table_name]

        # add an index to be useful to look up entries without arguments_hash.
        migration.execute 'CREATE INDEX memoized_attributes_idx ON memoized_values((arguments_hash IS NULL))'
      end
    end
  end
end
