module DbMemoize
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'tasks/clear.rake'
      load 'tasks/warmup.rake'
    end
  end
end
