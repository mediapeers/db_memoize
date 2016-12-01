module DbMemoize
  class Railtie < ::Rails::Railtie
    initializer 'Rails logger' do
      DbMemoize.logger = Rails.logger

      # by default invalidate cache when db schema has changed
      DbMemoize.default_custom_key = ActiveRecord::Migrator.current_version
    end

    rake_tasks do
      load 'tasks/clear.rake'
      load 'tasks/warmup.rake'
    end
  end
end
