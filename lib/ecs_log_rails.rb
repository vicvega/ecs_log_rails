require "lograge"
require "ecs_log_rails/ecs_formatter"

module EcsLogRails
  module_function

  mattr_accessor :application

  def setup(app)
    self.application = app
    validate_log_correlation!
    setup_lograge
    setup_custom_payload
    setup_logger
    setup_formatter
  end

  def setup_lograge
    # by default keep original rails log
    application.config.lograge.keep_original_rails_log = ecs_log_rails_config.keep_original_rails_log
    # custom options
    application.config.lograge.custom_options = ->(event) do
      options = {
        original_url: event.payload[:request]&.original_url,
        remote_ip: event.payload[:request]&.remote_ip,
        ip: event.payload[:request]&.ip,
        host: event.payload[:request]&.host,
        referrer: event.payload[:request]&.referer,
        params: event.payload[:params]&.except("controller", "action"),
        exception: event.payload[:exception],
        exception_object: event.payload[:exception_object]
      }

      if ecs_log_rails_config.log_correlation
        # Note: ElasticAPM.log_ids can yield nil values, or an empty string if called without a block,
        # when there's no active transaction/span. We use this signature to have more control.
        ElasticAPM.log_ids do |transaction_id, span_id, trace_id|
          options[:apm_transaction_id] = transaction_id if transaction_id
          options[:apm_span_id] = span_id if span_id
          options[:apm_trace_id] = trace_id if trace_id
        end
      end

      options
    end
    Lograge.setup(application)
  end

  def setup_logger
    Lograge.logger = ActiveSupport::Logger.new(ecs_log_rails_config.log_file)
    Lograge.log_level = ecs_log_rails_config.log_level
  end

  def setup_formatter
    Lograge.formatter = EcsFormatter.new(
      service_name: ecs_log_rails_config.service_name,
      service_env: ecs_log_rails_config.service_env,
      service_type: ecs_log_rails_config.service_type
    )
  end

  def setup_custom_payload
    return unless ecs_log_rails_config.custom_payload_method.respond_to?(:call)

    base_classes = Array(ecs_log_rails_config.base_controller_class)
    base_classes.map! { |klass| klass.try(:constantize) }
    base_classes << ActionController::Base if base_classes.empty?

    base_classes.each do |base_class|
      extend_base_class(base_class)
    end
  end

  def extend_base_class(klass)
    append_payload_method = klass.instance_method(:append_info_to_payload)
    custom_payload_method = ecs_log_rails_config.custom_payload_method

    klass.send(:define_method, :append_info_to_payload) do |payload|
      append_payload_method.bind_call(self, payload)
      payload[:custom_payload] = {ecs_custom: custom_payload_method.call(self)}
    end
  end

  def ecs_log_rails_config
    application.config.ecs_log_rails
  end

  def validate_log_correlation!
    return unless ecs_log_rails_config.log_correlation

    unless defined?(ElasticAPM)
      raise "EcsLogRails log_correlation is enabled but ElasticAPM is not defined. " \
            "Please add 'elastic-apm' gem to your Gemfile to be able to use log_correlation."
    end
  end
end
require "ecs_log_rails/railtie" if defined?(Rails)
