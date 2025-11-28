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

  def test_includes_apm_correlation_ids_when_present
    service_name = "test-service"
    service_env = "production"
    service_type = "rails"

    data = {
      apm_trace_id: "cd03e525c1c801cc666099d5c2108e4e",
      apm_transaction_id: "dbebf61570c4dd6e",
      apm_span_id: "960834f4538880a4"
    }

    formatter = EcsFormatter.new(
      service_name: service_name,
      service_env: service_env,
      service_type: service_type
    )

    result = JSON.parse(formatter.call(data))

    assert_equal "cd03e525c1c801cc666099d5c2108e4e", result["trace"]["id"]
    assert_equal "dbebf61570c4dd6e", result["transaction"]["id"]
    assert_equal "960834f4538880a4", result["span"]["id"]
  end

  def test_omits_apm_fields_when_not_present
    service_name = "test-service"
    service_env = "production"
    service_type = "rails"

    data = {}

    formatter = EcsFormatter.new(
      service_name: service_name,
      service_env: service_env,
      service_type: service_type
    )

    result = JSON.parse(formatter.call(data))

    refute result.key?("trace")
    refute result.key?("transaction")
    refute result.key?("span")
  end

  def test_handles_partial_apm_data
    service_name = "test-service"
    service_env = "production"
    service_type = "rails"

    data = {
      apm_trace_id: "cd03e525c1c801cc666099d5c2108e4e"
    }

    formatter = EcsFormatter.new(
      service_name: service_name,
      service_env: service_env,
      service_type: service_type
    )

    result = JSON.parse(formatter.call(data))

    assert_equal "cd03e525c1c801cc666099d5c2108e4e", result["trace"]["id"]
    refute result.key?("transaction")
    refute result.key?("span")
  end
end
