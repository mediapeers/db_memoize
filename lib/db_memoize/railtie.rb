module DbMemoize
  class Railtie < ::Rails::Railtie
    initializer 'Rails logger' do
      DbMemoize.logger = Rails.logger
    end

    rake_tasks do
      load 'tasks/clear.rake'
    end
  end
end
