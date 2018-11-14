require 'simple-sql'

module DbMemoize
  module Model
    extend ActiveSupport::Concern

    def memoized_value(method_name)
      memoizable = !changed? && persisted?
      return send("#{method_name}_without_memoize") unless memoizable

      memoized_value = find_memoized_value(method_name)

      if memoized_value
        memoized_value.value
      else
        value = send("#{method_name}_without_memoize")
        create_memoized_value(method_name, value)
        value
      end
    end

    def unmemoize(method_name = :all)
      self.class.unmemoize id, method_name
    end

    #
    # Used to set multiple memoized values in one go.
    #
    # Example:
    #
    #   product.memoize_values full_title: "my full title",
    #                          autocomplete_info: "my autocomplete_info"
    #
    # This sets the "full_title" and "autocomplete_info" values of the product.
    #
    def memoize_values(values)
      values.each do |name, value|
        create_memoized_value(name, value)
      end
    end

    private

    def create_memoized_value(method_name, value)
      self.class.transaction do
        ::DbMemoize::Value.fast_create self.class.table_name, id, method_name, value
        @association_cache.delete :memoized_values
        value
      end
    end

    def find_memoized_value(method_name)
      method_name = method_name.to_s

      # In order to prevent database level deadlocks we don't manage any unique
      # index on memoized values. This can result in duplicate matching memoized
      # values.
      #
      # It is important to always return the freshest value. To make sure this
      # happens the \a memoized_values association is ordered by its creation
      # time (via "created_at DESC"), which lets us just return the first matching
      # entry here.
      memoized_values.detect do |rec|
        rec.method_name == method_name
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

        DbMemoize::Value.where(conditions).delete_all_ordered
      end

      def memoize_values(records_or_ids, values)
        transaction do
          ids = Helpers.find_ids(records_or_ids)

          ids.each do |id|
            values.each do |method_name, value|
              ::DbMemoize::Value.fast_create table_name, id, method_name, value
            end
          end
        end
      end

      private

      # rubocop:disable Style/EmptyBlockParameter
      def create_memoized_alias_method(method_name)
        define_method "#{method_name}_with_memoize" do ||
          memoized_value(method_name)
        end

        alias_method_chain method_name, :memoize
      end

      # rubocop:disable Style/GuardClause
      def create_memoized_values_association
        unless reflect_on_association(:memoized_values)
          conditions = { entity_table_name: table_name }

          # By defining this before_destroy callback we make sure **we** delete all
          # memoized values before Rails deletes those via `has_many dependent:
          # This leads to has_many later on not finding any values to be deleted.
          #
          # It would be nice if there was a `dependent: :manual/:noop` option.
          #
          # **Note:** before_destroy must be called before memoized_values is
          # set up, to make sure that these things happen in the right order.
          #
          before_destroy do |rec|
            rec.memoized_values.delete_all_ordered
          end

          # memoized_values for this object. These values must be returned
          # newest first, see the comment in \a find_memoized_value.
          has_many :memoized_values, -> { where(conditions).order('created_at DESC') },
                   dependent: :delete_all, class_name: 'DbMemoize::Value', foreign_key: :entity_id

        end
      end
    end
  end
end
