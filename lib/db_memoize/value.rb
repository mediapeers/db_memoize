# rubocop:disable Metrics/CyclomaticComplexity

require 'simple-sql'
require 'json'

module DbMemoize
  class Value < ActiveRecord::Base
    self.table_name = 'db_memoize.memoized_values'

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
      else raise "Unsupported type #{value.class.name.inspect}, for DbMemoize"
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

    def self.fast_create(entity_table_name, entity_id, method_name, value)
      method_name = method_name.to_s

      # clear out old entry (if any). This makes sure that any existing value
      # is cleared out properly.
      SQL.ask "DELETE FROM #{table_name} WHERE(entity_table_name, entity_id, method_name) = ($1, $2, $3)",
              entity_table_name, entity_id, method_name

      column = case value
               when String   then :val_string
               when Integer  then :val_integer
               when Float    then :val_float
               when Time     then :val_time
               when false    then :val_boolean
               when true     then :val_boolean
               when nil      then :val_nil
               when Hash     then :val_object
               when Array    then :val_object
               else
                 raise "Unsupported value of type #{value.class.name}: #{value.inspect}"
               end

      value = JSON.generate(value) if column == :val_object

      # it looks like Simple::SQL somehow drops subsecond resolutions from
      # time objects. AR does not, though. So, for time values, we use the
      # ActiveRecord method; for everything else we use Simple::SQL (for
      # performance reasons: it is 10 times as fast.)
      if column != :val_time
        simple_sql_create_value column, entity_table_name: entity_table_name, entity_id: entity_id,
                                        method_name: method_name, value: value
      else
        ar_create_value column, entity_table_name: entity_table_name, entity_id: entity_id,
                                method_name: method_name, value: value
      end
    end

    def self.simple_sql_create_value(column, entity_table_name:, entity_id:, method_name:, value:)
      sql = <<~SQL.freeze
        INSERT INTO #{table_name}
          (entity_table_name, entity_id, method_name, #{column}, created_at)
          VALUES($1,$2,$3,$4,NOW())
      SQL

      SQL.ask sql, entity_table_name, entity_id, method_name, value
    end

    def self.ar_create_value(column, entity_table_name:, entity_id:, method_name:, value:)
      data = {
        :entity_table_name => entity_table_name,
        :entity_id => entity_id,
        :method_name => method_name,
        column => value
      }

      create!(data)
    end
  end
end
