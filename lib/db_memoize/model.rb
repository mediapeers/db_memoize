module DbMemoize
  module Model
    extend ActiveSupport::Concern

    def memoized_value(method_name, args)
      if changed? || !persisted?
        return send("#{method_name}_without_memoize", *args)
      end

      value         = nil
      args_hash     = Helpers.calculate_arguments_hash(args)
      cached_value  = find_memoized_value(method_name, args_hash)

      if cached_value
        value = Marshal.load(cached_value.value)
        Helpers.log(self, method_name, 'cache hit')
      else
        time = ::Benchmark.realtime do
          value = send("#{method_name}_without_memoize", *args)
          create_memoized_value(method_name, args_hash, value)
        end
        Helpers.log(self, method_name, "cache miss. took #{Kernel.format '%.2f msecs', time * 1_000}")
      end

      value
    end

    def unmemoize(method_name = :all)
      if method_name != :all
        # FIXME: this works, but isn't immediately visible on the record.
        # See also note in create_memoized_value.
        memoized_values.where(method_name: method_name).delete_all
      else
        memoized_values.clear
      end
    end

    #
    # Used to set multiple memoized values in one go.
    #
    # Example:
    #
    #   product.memoize_values full_title: "my full title",
    #                          autocomplete_info: "my autocomplete_info"
    #
    def memoize_values(values, *args)
      # [TODO] - when creating many memoized values: should we even support arguments here?
      args_hash = Helpers.calculate_arguments_hash(args)

      values.each do |name, value|
        create_memoized_value(name, args_hash, value)
      end
    end

    private

    def create_memoized_value(method_name, args_hash, value)
      # [TODO] - It would be nice to have an optimized, pg-based inserter
      #          here, for up to 10 times speed. However, the memoized_values
      #          array must then be properly reset.
      memoized_values.create!(
        entity_table_name: self.class.table_name,
        method_name: method_name.to_s,
        arguments_hash: args_hash,
        value: Marshal.dump(value)
      )
    end

    def find_memoized_value(method_name, args_hash)
      method_name = method_name.to_s

      memoized_values.detect do |rec|
        rec.method_name == method_name &&
          rec.arguments_hash == args_hash
      end
    end

    module ClassMethods
      def db_memoize(method_name)
        @db_memoized_methods ||= []
        @db_memoized_methods.push(method_name.to_sym)

        # [TODO] - should the create_memoized_** functions really be called
        # when the method_name is in @db_memoized_methods already?
        create_memoized_alias_method(method_name)
        create_memoized_values_association
      end

      def db_memoized_methods
        methods = @db_memoized_methods || []
        superclass.respond_to?(:db_memoized_methods) ? (superclass.db_memoized_methods + methods).uniq : methods
      end

      def unmemoize(records_or_ids, method_name = :all)
        conditions = {
          entity_table_name: table_name,
          entity_id: Helpers.find_ids(records_or_ids)
        }
        conditions[:method_name] = method_name unless method_name == :all

        DbMemoize::Value.where(conditions).delete_all
      end

      def memoize_values(records_or_ids, values, *args)
        # [TODO] - when creating many memoized values: should we even support arguments here?
        transaction do
          ids        = Helpers.find_ids(records_or_ids)
          args_hash  = Helpers.calculate_arguments_hash(args)

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

      def create_memoized_alias_method(method_name)
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
