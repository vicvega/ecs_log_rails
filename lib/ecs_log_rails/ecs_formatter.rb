require "logstash-event"
require_relative "ecs_formatter/factory"
require_relative "ecs_formatter/ecs_generator"
require_relative "ecs_formatter/controller"
require_relative "ecs_formatter/active_job"

class EcsFormatter
  attr_reader :service_env, :service_name, :service_type

  def initialize(service_name:, service_type:, service_env:)
    @service_name = service_name.freeze
    @service_env = service_env.freeze
    @service_type = service_type.freeze
    @data = nil
  end

  def call(data)
    @data = data

    Factory.build(@data, service_name:, service_type:, service_env:)
      .generate_ecs
      .then { deep_compact(it) }
      .then { LogStash::Event.new(it) }
      .to_json
      .freeze
  end

  private

  def deep_compact(hash)
    res_hash = hash.map do |key, value|
      value = deep_compact(value) if value.is_a?(Hash)

      value = nil if [{}, []].include?(value)
      [key, value]
    end
    res_hash.to_h.compact
  end
end
