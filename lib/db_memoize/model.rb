module DbMemoize
  module Model
    extend ActiveSupport::Concern

    def memoized_value(method_name, args)
      if changed? || !persisted?
        return send("#{method_name}_without_memoize", *args)
      end

      args_hash     = ::Digest::MD5.hexdigest(Marshal.dump(args))
      cached_value  = find_memoized_value(method_name, args_hash)

      unless cached_value
        cached_value = send("#{method_name}_without_memoize", *args)
        create_memoized_value(method_name, args_hash, cached_value)
      end

      cached_value
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
        method_name: method_name,
        arguments_hash: args_hash,
        custom_key: memoized_custom_key,
        value: Marshal.dump(value)
      )
    end

    def find_memoized_value(method_name, args_hash)
      entry = memoized_values.detect do |rec|
        rec.method_name == method_name.to_s &&
          rec.arguments_hash == args_hash &&
          rec.custom_key == memoized_custom_key
      end

      entry && Marshal.load(entry.value)
    end

    module ClassMethods
      def db_memoize(method_name)
        create_alias_method(method_name)
        create_memoized_values_association
      end

      def unmemoize(records_or_ids, method_name = :all)
        records_or_ids = Array(records_or_ids)
        return if records_or_ids.empty?

        if records_or_ids.first.is_a?(ActiveRecord::Base)
          types = records_or_ids.map { |r| r.class.name }.uniq
          ids   = records_or_ids.map(&:id)
        else
          types = name
          ids   = records_or_ids
        end

        conditions = {
          entity_type: types,
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
          has_many :memoized_values, dependent: :destroy, class_name: 'DbMemoize::Value', as: :entity
        end
      end
    end
  end
end
