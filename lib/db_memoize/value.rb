module DbMemoize
  class Value < ActiveRecord::Base
    self.table_name = 'memoized_values'

    include DbMemoize::Metal

    def self.delete_all_ordered
      relation = self
      relation = all unless is_a?(ActiveRecord::Relation)

      sql = relation.select(:ctid).to_sql
      connection.execute <<-SQL
        DO $$DECLARE c record;
        BEGIN
          FOR c IN #{sql} ORDER BY ctid LOOP
            DELETE FROM #{DbMemoize::Value.table_name} WHERE ctid = c.ctid;
          END LOOP;
        END$$;
      SQL
    end
  end
end
