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
          FOR c IN SELECT * FROM (#{sql}) sq ORDER BY ctid LOOP
            DELETE FROM #{DbMemoize::Value.table_name} WHERE ctid = c.ctid;
          END LOOP;
        END$$;
      SQL
    end

    ALL_COLUMNS = [
      :val_string,
      :val_integer,
      :val_float,
      :val_time,
      :val_object,
      :val_boolean,
      :val_nil
    ].freeze

    def self.fast_create(entity_table_name, entity_id, method_name, value)
      method_name = method_name.to_s

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

      # some types need special encoding
      case column
      when :val_object  then value = _reformat_object(value)
      when :val_time    then value = _reformat_time(value)
      end

      # We initialize created_at with +statement_timestamp()+ since this
      # reflects the current time when running the insert, resulting in
      # increasing timestamps even within the same transaction.
      #
      # (This is only relevant for tests, though.)
      sql = <<~SQL.freeze
        INSERT INTO #{table_name}(entity_table_name, entity_id, method_name, #{column}, created_at)
          VALUES($1,$2,$3,$4,statement_timestamp())
      SQL

      SQL.ask sql, entity_table_name, entity_id, method_name, value
    end

    # Apparently the pg, and for that matter also simple-sql, drops subsecond
    # resolution when passing in time objects. (Note that this seems not always
    # to be the case, it probably depends on some encoder configuration within
    # pg - which simple-sql is not touching, since this is a setting on a
    # connection which might not be exclusive to simple-sql.)
    #
    # Instead we'll just pass along a string, postgresql will then convert it
    # into a proper timestamp.
    def self._reformat_time(t) # rubocop:disable Naming/UncommunicativeMethodParamName
      format('%04d-%02d-%02d %02d:%02d:%02d.%06d', t.year, t.mon, t.day, t.hour, t.min, t.sec, t.usec)
    end

    def self._reformat_object(value)
      JSON.generate(value)
    end
  end
end
