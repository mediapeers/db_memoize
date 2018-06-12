# rubocop:disable Metrics/CyclomaticComplexity

require 'simple-sql'
require 'json'

module DbMemoize
  class Value < ActiveRecord::Base
    self.table_name = 'memoized_values'

    SQL = ::Simple::SQL

    def value=(value)
      self.val_integer = self.val_float = self.val_string = self.val_boolean = self.val_time = nil

      case value
      when String   then self.val_string = value
      when Integer  then self.val_integer = value
      when Float    then self.val_float = value
      when Time     then self.val_time = value
      when false    then self.val_boolean = value
      when true     then self.val_boolean = value
      when nil      then :nop
      end
    end

    def value
      # Note: val_boolean should come last.
      val_string || val_integer || val_float || val_time || val_object || val_boolean
    end

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

    def self.fast_create(entity_table_name, id, method_name, value)
      method_name = method_name.to_s

      # clear out old entry (if any). This makes sure that any existing value
      # is cleared out properly.
      SQL.ask "DELETE FROM #{table_name} WHERE(entity_table_name, entity_id, method_name) = ($1, $2, $3)",
              entity_table_name, id, method_name

      dest_column = case value
                    when String   then :val_string
                    when Integer  then :val_integer
                    when Float    then :val_float
                    when Time     then :val_time
                    when false    then :val_boolean
                    when nil      then :val_nil
                    when Hash     then :val_object
                    when Array    then :val_object
                    else
                      raise "Unsupported value of type #{value.class.name}: #{value.inspect}"
                    end

      value = JSON.generate(value) if dest_column == :val_object
      sql = <<~SQL.freeze
        INSERT INTO #{table_name}
          (entity_table_name, entity_id, method_name, #{dest_column}, created_at)
          VALUES($1,$2,$3,$4,NOW())
        SQL

      SQL.ask sql, entity_table_name, id, method_name, value
    end
  end
end
