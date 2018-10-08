module DbMemoize
  class Migrations
    class << self
      def create_tables(migration)
        migration.execute <<~SQL
          CREATE TABLE IF NOT EXISTS memoized_values (
            entity_table_name varchar,
            entity_id integer,
            method_name varchar,
            created_at timestamp without time zone
          );

          -- entity_id/entity_table_name should have a better chance to be useful, since
          -- there is more variance in entity_ids than there is in entity_table_names.
          DROP INDEX IF EXISTS index_memoized_values_on_entity_id_and_entity_table_name;
          DROP INDEX IF EXISTS index_memoized_values_on_entity_table_name_and_entity_id;
          CREATE UNIQUE INDEX IF NOT EXISTS memoized_attributes_idx2
            ON memoized_values(entity_id, entity_table_name, method_name);

          ALTER TABLE memoized_values DROP COLUMN IF EXISTS arguments_hash;
          ALTER TABLE memoized_values DROP COLUMN IF EXISTS value;

          ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_string varchar;
          ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_integer bigint;
          ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_float double precision;
          ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_time timestamp without time zone;
          ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_object jsonb;
          ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_boolean boolean;
          ALTER TABLE memoized_values ADD COLUMN IF NOT EXISTS val_nil boolean;
        SQL
      end
    end
  end
end
