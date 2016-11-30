module DbMemoize
  class Railtie < ::Rails::Railtie
    initializer 'Rails logger' do
      DbMemoize.logger = Rails.logger
    end
  end
end
