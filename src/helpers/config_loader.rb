module ConfigLoader
  def self.registered(app)
    app.helpers LinkHelper
    app.register ErrorHandler

    app.configure do
      app.set :per_page, 10
    end

    app.configure :development do
      app.register Sinatra::Reloader
    end
  end
end
