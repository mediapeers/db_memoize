module DbMemoize
  class Migrations
    class << self
      def create_tables(migration)
        migration.create_table :memoized_values, id: false do |t|
          t.string :entity_table_name, null: false
          t.integer :entity_id, null: false
          t.string :method_name, null: false
          t.string :arguments_hash
          t.binary :value
          t.datetime :created_at, null: false
        end

        migration.add_index :memoized_values, [:entity_table_name, :entity_id]
        migrate_empty_arguments_support(migration)
        drop_arguments_support(migration)
        add_discrete_value_columns(migration)
      end

      def migrate_empty_arguments_support(migration)
        # entity_id/entity_table_name should have a better chance to be useful, since
        # there is more variance in entity_ids than there is in entity_table_names.
        migration.remove_index :memoized_values, [:entity_table_name, :entity_id]
        migration.add_index :memoized_values, [:entity_id, :entity_table_name]

        # add an index to be useful to look up entries where arguments_hash is NULL.
        # (which is the case for plain attributes of an object)
        migration.execute 'CREATE INDEX IF NOT EXISTS memoized_attributes_idx ON memoized_values((arguments_hash IS NULL))'
      end

      def drop_arguments_support(migration)
        migration.execute 'DROP INDEX IF EXISTS memoized_attributes_idx'
        migration.execute 'ALTER TABLE memoized_values DROP COLUMN IF EXISTS arguments_hash'

        migration.remove_index :memoized_values, [:entity_id, :entity_table_name]
        migration.add_index :memoized_values, [:entity_id, :entity_table_name, :method_name], unique: true, name: 'memoized_attributes_idx2'
      end

      def add_discrete_value_columns(m)
        m.execute 'ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_string varchar'
        m.execute 'ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_integer bigint'
        m.execute 'ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_float double precision'
        m.execute 'ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_time timestamp without time zone'
        m.execute 'ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_boolean boolean'
        m.execute 'ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_object jsonb'
        m.execute 'ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_nil boolean'
      end
    end
  end
end
