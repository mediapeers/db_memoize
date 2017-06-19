module ActiveRecord
  module Metal
    def self.included(base)
      base.extend ClassMethods
      # base.metal # initialize the metal adapter
    end

    module ClassMethods
      def metal
        @metal ||= Adapter.new(self)
      end
    end

    class Adapter
      ColumnInfo = Struct.new(:column, :type) unless defined?(ColumnInfo)

      def initialize(base_klass)
        @base_klass  = base_klass

        # setup primary key information. This is necessary to allow the create! method
        # to return the primary key of a newly created entry.
        pk_column    = @base_klass.primary_key
        pk_type      = @base_klass.columns_hash.fetch(pk_column).type if pk_column
        @primary_key = ColumnInfo.new(pk_column, pk_type)
      end

      attr_reader :primary_key

      private

      def table_name
        @base_klass.table_name
      end

      def raw_connection
        @base_klass.connection.raw_connection # do not memoize me!
      end

      def column?(column_name)
        @base_klass.columns_hash.key?(column_name)
      end

      def sql_cache
        @sql_cache ||= {}
      end

      def insert_sql(field_names)
        sql_cache[[:insert_sql, field_names]] ||= _insert_sql(field_names)
      end

      def _insert_sql(field_names)
        placeholders = 0.upto(field_names.count - 1).map { |idx| "$#{idx + 1}" }

        if column?('created_at')
          field_names << 'created_at'
          placeholders << 'current_timestamp'
        end

        if column?('updated_at')
          field_names << 'updated_at'
          placeholders << 'current_timestamp'
        end

        sql = "INSERT INTO #{table_name} (#{field_names.join(',')}) VALUES(#{placeholders.join(',')})"
        sql += " RETURNING #{primary_key.column}" if primary_key.column
        sql
      end

      public

      def create!(record)
        keys, values = record.to_a.transpose

        sql    = insert_sql(keys)
        result = raw_connection.exec_params(sql, values)

        # if we don't have an ID column then the sql does not return any value. The result
        # object would be this: #<PG::Result status=PGRES_COMMAND_OK ntuples=0 nfields=0 cmd_tuples=1>
        # we just return nil in that case; otherwise we return the first entry of the first result row
        # which would be the stringified id.
        first_row = result.each_row.first
        return nil unless first_row

        id = first_row.first
        primary_key.type == :integer ? Integer(id) : id
      end
    end
  end
end
