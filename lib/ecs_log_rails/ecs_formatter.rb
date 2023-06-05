require "logstash-event"

class EcsFormatter
  attr_reader :ecs_data, :data, :service_env, :service_name, :service_type

  def initialize(service_name:, service_type:, service_env:)
    @service_name = service_name
    @service_env = service_env
    @service_type = service_type
  end

  def call(data)
    @data = data
    generate_ecs
    event = LogStash::Event.new(deep_compact(ecs_data))
    event.to_json
  end

  private

  def generate_ecs
    init_ecs
    add_http
    add_url
    add_event
    add_source
    add_destination
    add_service
    add_rails
    add_error
    add_custom_payload
  end

  def init_ecs
    @ecs_data = {}
  end

  def add_http
    ecs_add(:http, {
      request: {
        method: data[:method],
        referrer: data[:referrer]
      },
      response: {
        mime_type: data[:format],
        status_code: data[:status]
      }
    })
  end

  def add_url
    ecs_add(:url, {
      path: data[:path],
      original: data[:original_url]
    })
  end

  def add_event
    ecs_add(:event, {
      kind: "event",
      # ECS event duration in nanoseconds
      duration: nanoseconds(data[:duration])
    })
  end

  def add_source
    ecs_add(:source, {
      ip: data[:remote_ip]
    })
  end

  def add_destination
    ecs_add(:destination, {
      ip: data[:ip],
      name: data[:host]
    })
  end

  def add_service
    ecs_add(:service, {
      name: service_name,
      type: service_type,
      environment: service_env
    })
  end

  def add_rails
    ecs_add(:rails, {
      controller: data[:controller],
      action: data[:action],
      params: data[:params],
      view_runtime: data[:view],
      db_runtime: data[:db]
    })
  end

  def add_error
    ecs_add(:error, {
      type: data[:exception]&.first,
      message: data[:exception]&.last,
      stack_trace: data[:exception_object]&.backtrace&.join("\n")
    })
  end

  def add_custom_payload
    return if data[:ecs_custom].nil?

    ecs_data.merge!(data[:ecs_custom])
  end

  def deep_compact(hash)
    res_hash = hash.map do |key, value|
      value = deep_compact(value) if value.is_a?(Hash)

      value = nil if [{}, []].include?(value)
      [key, value]
    end
    res_hash.to_h.compact
  end

  def ecs_add(key, value)
    ecs_data.store(key, value)
  end

  def nanoseconds(ms)
    return if ms.nil?

    (ms * 1_000_000).to_i
  end
end
