require 'simple-sql'

module DbMemoize
  class Value < ActiveRecord::Base
    self.table_name = 'memoized_values'

    SQL = ::Simple::SQL

    def self.delete_all_ordered
      relation = self
      relation = all unless is_a?(ActiveRecord::Relation)

      sql = relation.select(:ctid).to_sql
      SQL.ask <<-SQL
        DO $$DECLARE c record;
        BEGIN
          FOR c IN #{sql} ORDER BY ctid LOOP
            DELETE FROM #{DbMemoize::Value.table_name} WHERE ctid = c.ctid;
          END LOOP;
        END$$;
      SQL
    end

    INSERT_SQL = <<~SQL.freeze
      INSERT INTO #{table_name}
        (entity_table_name, entity_id, method_name, value, created_at)
        VALUES($1,$2,$3,$4,NOW())
      SQL

    def self.fast_create(entity_table_name, id, method_name, value)
      SQL.ask INSERT_SQL, entity_table_name,
              id,
              method_name.to_s,
              Helpers.marshal(value)
    end
  end
end
