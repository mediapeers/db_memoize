namespace :db_memoize do
  desc "wipes all currently memoized values (pass 'class=Product') to filter by class name"
  task clear: :environment do
    klass_name = ENV['class']

    scope = DbMemoize::Value.all
    scope = scope.where(entity_type: klass_name) if klass_name

    scope.delete_all
  end
end
