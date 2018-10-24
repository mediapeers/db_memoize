module DbMemoize
  class Migrations
    class << self
      def create_tables(migration)
        migration.execute <<~SQL
          CREATE SCHEMA IF NOT EXISTS db_memoize;

          CREATE TABLE IF NOT EXISTS db_memoize.memoized_values (
            entity_table_name varchar NOT NULL,
            entity_id integer NOT NULL,
            method_name varchar NOT NULL,
            created_at timestamp without time zone NOT NULL
          );

          -- entity_id/entity_table_name should have a better chance to be useful, since
          -- there is more variance in entity_ids than there is in entity_table_names.
          DROP INDEX IF EXISTS index_memoized_values_on_entity_id_and_entity_table_name;
          DROP INDEX IF EXISTS index_memoized_values_on_entity_table_name_and_entity_id;
          CREATE UNIQUE INDEX IF NOT EXISTS memoized_attributes_idx2
            ON db_memoize.memoized_values(entity_id, entity_table_name, method_name);

          ALTER TABLE db_memoize.memoized_values DROP COLUMN IF EXISTS arguments_hash;
          ALTER TABLE db_memoize.memoized_values DROP COLUMN IF EXISTS value;

          ALTER TABLE db_memoize.memoized_values ADD COLUMN IF NOT EXISTS val_string varchar;
          ALTER TABLE db_memoize.memoized_values ADD COLUMN IF NOT EXISTS val_integer bigint;
          ALTER TABLE db_memoize.memoized_values ADD COLUMN IF NOT EXISTS val_float double precision;
          ALTER TABLE db_memoize.memoized_values ADD COLUMN IF NOT EXISTS val_time timestamp without time zone;
          ALTER TABLE db_memoize.memoized_values ADD COLUMN IF NOT EXISTS val_object jsonb;
          ALTER TABLE db_memoize.memoized_values ADD COLUMN IF NOT EXISTS val_boolean boolean;
          ALTER TABLE db_memoize.memoized_values ADD COLUMN IF NOT EXISTS val_nil boolean;
        SQL
      end
    end
  end
end
