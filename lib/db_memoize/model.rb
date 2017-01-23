module DbMemoize
  module Model
    extend ActiveSupport::Concern

    def memoized_value(method_name, args)
      if changed? || !persisted?
        return send("#{method_name}_without_memoize", *args)
      end

      value         = nil
      args_hash     = ::Digest::MD5.hexdigest(Marshal.dump(args))
      cached_value  = find_memoized_value(method_name, args_hash)

      if cached_value
        log(method_name, 'cache hit')
        value = Marshal.load(cached_value.value)
      else
        time = ::Benchmark.realtime do
          value = send("#{method_name}_without_memoize", *args)
        end
        # dear rubocop, we can't use `format` here, since some of our models have a
        # `format` method themselves.
        # rubocop:disable Style/FormatString
        log(method_name, "cache miss. took #{sprintf('%.2f', time * 1_000)}ms")
        # rubocop:enable Style/FormatString
        create_memoized_value(method_name, args_hash, value)
      end

      value
    end

    def unmemoize(method_name = :all)
      if method_name != :all
        # FIXME: this works, but isn't immediately visible on the record
        memoized_values.where(method_name: method_name).delete_all
      else
        memoized_values.clear
      end
    end

    def memoize_values(values, *args)
      args_hash = ::Digest::MD5.hexdigest(Marshal.dump(args))

      values.each do |name, value|
        create_memoized_value(name, args_hash, value)
      end
    end

    private

    def create_memoized_value(method_name, args_hash, value)
      memoized_values.create!(
        entity_table_name: self.class.table_name,
        method_name: method_name.to_s,
        arguments_hash: args_hash,
        value: Marshal.dump(value)
      )
    end

    def find_memoized_value(method_name, args_hash)
      memoized_values.detect do |rec|
        rec.method_name == method_name.to_s &&
          rec.arguments_hash == args_hash
      end
    end

    def log(method_name, msg)
      DbMemoize.logger.info "DbMemoize <#{self.class.name} id: #{id}>##{method_name} - #{msg}"
    end

    module ClassMethods
      def db_memoize(method_name)
        create_alias_method(method_name)
        create_memoized_values_association
      end

      def unmemoize(records_or_ids, method_name = :all)
        conditions = {
          entity_table_name: table_name,
          entity_id: find_ids(records_or_ids)
        }
        conditions[:method_name] = method_name unless method_name == :all

        DbMemoize::Value.where(conditions).delete_all
      end

      def memoize_values(records_or_ids, values, *args)
        transaction do
          ids        = find_ids(records_or_ids)
          args_hash  = ::Digest::MD5.hexdigest(Marshal.dump(args))

          ids.each do |id|
            values.each do |name, value|
              DbMemoize::Value.create!(
                entity_table_name: table_name,
                entity_id: id,
                method_name: name,
                arguments_hash: args_hash,
                value: Marshal.dump(value)
              )
            end
          end
        end
      end

      private

      def find_ids(records_or_ids)
        records_or_ids = Array(records_or_ids)
        return [] if records_or_ids.empty?

        records_or_ids.first.is_a?(ActiveRecord::Base) ? records_or_ids.map(&:id) : records_or_ids
      end

      def create_alias_method(method_name)
        define_method "#{method_name}_with_memoize" do |*args|
          memoized_value(method_name, args)
        end

        alias_method_chain method_name, :memoize
      end

      def create_memoized_values_association
        unless reflect_on_association(:memoized_values)
          conditions = { entity_table_name: table_name }
          has_many :memoized_values, -> { where(conditions) },
                   dependent: :delete_all, class_name: 'DbMemoize::Value', foreign_key: :entity_id
        end
      end
    end
  end
end
