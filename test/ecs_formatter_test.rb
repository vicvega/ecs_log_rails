require "test_helper"
require "ecs_log_rails/ecs_formatter"

class EcsFormatterTest < Minitest::Test
  def test_service_name_should_be_configurable
    service_name = "service name"
    service_env = "service environment"
    service_type = "service type"

    expected = {
      "name" => service_name,
      "environment" => service_env,
      "type" => service_type
    }

    got = JSON.parse(EcsFormatter.new(
      service_name: service_name,
      service_env: service_env,
      service_type: service_type
    ).call({}))

    assert_equal expected, got["service"]
  end
end
