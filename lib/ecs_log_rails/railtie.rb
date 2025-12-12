require "rails/railtie"
require "ecs_log_rails/ordered_options"

module EcsLogRails
  class Railtie < Rails::Railtie
    config.ecs_log_rails = EcsLogRails::OrderedOptions.new
    config.ecs_log_rails.enabled = false
    config.ecs_log_rails.keep_original_rails_log = true
    config.ecs_log_rails.log_level = :info
    config.ecs_log_rails.log_file = File.join("log", "ecs_log_rails.log")
    config.ecs_log_rails.service_env = Rails.env
    config.ecs_log_rails.service_type = "rails"

    config.after_initialize do |app|
      app.config.ecs_log_rails.service_name ||= Rails.application.class.module_parent.name
      app.config.lograge.enabled = app.config.ecs_log_rails.enabled

      EcsLogRails.setup(app) if app.config.ecs_log_rails.enabled
    end
  end
end
