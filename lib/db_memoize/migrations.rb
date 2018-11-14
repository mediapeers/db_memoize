module DbMemoize
  class Migrations
    class << self
      def create_tables(migration)
        migration.execute <<~SQL
          CREATE SCHEMA IF NOT EXISTS db_memoize;

          CREATE TABLE IF NOT EXISTS db_memoize.memoized_values (
            entity_table_name varchar NOT NULL,
            entity_id         integer NOT NULL,
            method_name       varchar NOT NULL,

            val_string        varchar,
            val_integer       bigint,
            val_float         double precision,
            val_time          timestamp without time zone,
            val_object        jsonb,
            val_boolean       boolean,
            val_nil           boolean,
            created_at        timestamp without time zone NOT NULL
          );

          -- entity_id/entity_table_name should have a better chance to be useful, since
          -- there is more variance in entity_ids than there is in entity_table_names.
          DROP INDEX IF EXISTS db_memoize.memoized_attributes_idx2;

          CREATE INDEX IF NOT EXISTS memoized_attributes_idx3
            ON db_memoize.memoized_values(entity_id, entity_table_name);
        SQL
      end
    end
  end
end
