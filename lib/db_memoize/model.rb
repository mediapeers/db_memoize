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
      self.class.unmemoize(self, method_name)
    end

    def memoized_custom_key
      ::DbMemoize.default_custom_key
    end

    private

    def create_memoized_value(method_name, args_hash, value)
      memoized_values.create!(
        entity_table_name: self.class.table_name,
        method_name: method_name.to_s,
        arguments_hash: args_hash,
        custom_key: memoized_custom_key.to_s,
        value: Marshal.dump(value)
      )
    end

    def find_memoized_value(method_name, args_hash)
      memoized_values.detect do |rec|
        rec.method_name == method_name.to_s &&
          rec.arguments_hash == args_hash &&
          rec.custom_key == memoized_custom_key.to_s
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
        records_or_ids = Array(records_or_ids)
        return if records_or_ids.empty?

        ids = if records_or_ids.first.is_a?(ActiveRecord::Base)
                records_or_ids.map(&:id)
              else
                records_or_ids
              end

        conditions = {
          entity_table_name: table_name,
          entity_id: ids
        }
        conditions[:method_name] = method_name unless method_name == :all

        DbMemoize::Value.where(conditions).delete_all
      end

      private

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
                   dependent: :destroy, class_name: 'DbMemoize::Value', foreign_key: :entity_id
        end
      end
    end
  end
end
