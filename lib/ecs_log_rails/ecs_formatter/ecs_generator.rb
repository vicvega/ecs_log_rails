class EcsFormatter
  module EcsGenerator
    private attr_reader :data, :ecs_data, :service_name, :service_type, :service_env

    def initialize(data, service_name:, service_type:, service_env:)
      @data = data
      @service_name = service_name
      @service_type = service_type
      @service_env = service_env
      init_ecs
    end

    private

    def init_ecs
      @ecs_data = {}
    end

    def add_error
      ecs_add(:error, {
        type: data[:exception]&.first,
        message: data[:exception]&.last,
        stack_trace: data[:exception_object]&.backtrace&.join("\n")
      })
    end

    def add_event
      ecs_add(:event, {
        kind: "event",
        name: data[:event_name],
        # ECS event duration in nanoseconds
        duration: nanoseconds(data[:duration])
      })
    end

    def add_service
      ecs_add(:service, {
        name: service_name,
        type: service_type,
        environment: service_env
      })
    end

    def add_custom_payload
      return ecs_data if data[:ecs_custom].nil?

      ecs_data.merge!(data[:ecs_custom])
    end

    def ecs_add(key, value)
      ecs_data.store(key, value)
    end

    def nanoseconds(ms)
      return if ms.nil?

      (ms * 1_000_000).to_i
    end
  end
end
