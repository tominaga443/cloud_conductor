require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require 'devise/orm/active_record'

module CloudConductor
  class Application < Rails::Application
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    config.after_initialize do
      CloudConductor::Config.from_file "#{config.root}/config/config.rb"

      # config.application_logger = CloudConductor::Logger.new("#{config.root}/log/conductor_#{Rails.env}.log")
      config.application_logger = CloudConductor::Logger.init("#{config.root}/log/conductor_#{Rails.env}.log")
      # TODO: remove global constant
      ::Log = CloudConductor::Logger
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    I18n.available_locales = [:en]
  end
end
