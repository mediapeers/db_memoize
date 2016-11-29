module DbMemoize
  class Migrations
    class << self
      def create_memoized_values_table(migration)
        migration.create_table :memoized_values, id: false do |t|
          t.string :record_type
          t.string :record_id
          t.string :method_name
          t.string :arguments_hash
          t.string :custom_key
          t.text :value
          t.datetime :created_at
        end
      end
    end
  end
end
