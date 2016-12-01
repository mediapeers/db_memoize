namespace :db_memoize do
  desc "wipes all currently memoized values (pass 'class=Product') to filter by class name"
  task clear: :environment do
    scope = DbMemoize::Value.all

    if klass_name = ENV['class']
      scope = scope.where(entity_table_name: klass_name.constantize.table_name)
    end

    scope.delete_all
  end
end
