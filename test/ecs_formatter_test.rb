require "test_helper"
require "ecs_log_rails/ecs_formatter"

class EcsFormatterTest < Minitest::Test
  include EcsFormatterFixtures

  def test_service
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

  def test_service_attributes_are_frozen
    formatter = EcsFormatter.new(**service_config)

    assert formatter.service_name.frozen?
    assert formatter.service_type.frozen?
    assert formatter.service_env.frozen?
  end

  def test_returns_json_string
    formatter = EcsFormatter.new(**service_config)
    result = formatter.call(controller_data)

    assert_kind_of String, result
  end

  def test_returned_json_string_is_frozen
    result = EcsFormatter.new(**service_config).call({})

    assert_predicate result, :frozen?
  end

  def test_returns_valid_json
    formatter = EcsFormatter.new(**service_config)
    result = formatter.call(controller_data)

    assert JSON.parse(result)
  end

  def test_includes_metadata
    formatter = EcsFormatter.new(**service_config)
    result = JSON.parse(formatter.call(controller_data))

    assert result.key?("@timestamp")
    assert result.key?("@version")
  end

  def test_multiple_calls_are_independent
    formatter = EcsFormatter.new(**service_config)

    result1 = JSON.parse(formatter.call(method: "GET", path: "/first"))
    result2 = JSON.parse(formatter.call(method: "POST", path: "/second"))

    assert_equal "GET", result1["http"]["request"]["method"]
    assert_equal "POST", result2["http"]["request"]["method"]
    assert_equal "/first", result1["url"]["path"]
    assert_equal "/second", result2["url"]["path"]
  end

  def test_deep_compact_removes_empty_hashes
    formatter = EcsFormatter.new(**service_config)
    data = controller_data.merge(params: {})

    result = JSON.parse(formatter.call(data))

    refute result.fetch("rails").key?("params")
  end

  def test_deep_compact_removes_empty_arrays
    formatter = EcsFormatter.new(**service_config)
    data = controller_data.merge(
      ecs_custom: { empty_array: [] }
    )

    result = JSON.parse(formatter.call(data))

    refute result.key?("empty_array")
  end

  def test_deep_compact_removes_nil_values
    formatter = EcsFormatter.new(**service_config)
    data = controller_data.merge(
      ecs_custom: { nil_value: nil }
    )

    result = JSON.parse(formatter.call(data))

    refute result.key?("nil_value")
  end

  def test_deep_compact_preserves_scalar_values
    formatter = EcsFormatter.new(**service_config)
    data = controller_data.merge(
      ecs_custom: { flag: false, count: 0, message: "" }
    )

    result = JSON.parse(formatter.call(data))

    assert_equal false, result["flag"]
    assert_equal 0, result["count"]
    assert_equal "", result["message"]
  end

  def test_deep_compact_handles_deeply_nested_empty_values
    formatter = EcsFormatter.new(**service_config)
    data = controller_data.merge(
      ecs_custom: {
        level1: {
          level2: {
            level3: {}
          }
        }
      }
    )

    result = JSON.parse(formatter.call(data))

    refute result.key?("level1")
  end
end

class EcsFormatterFactoryTest < Minitest::Test
  include EcsFormatterFixtures

  def test_cannot_be_instantiated_directly
    error = assert_raises NoMethodError do
      EcsFormatter::Factory.new({}, **service_config)
    end
    assert_match %r(private method 'new' called for class EcsFormatter::Factory), error.message
  end

  def test_builds_controller_for_data_without_event_name
    formatter = EcsFormatter::Factory.build(controller_data, **service_config)

    assert_instance_of EcsFormatter::Controller, formatter
  end

  def test_builds_controller_for_data_with_random_event_name
    data = { event_name: "pippero" }
    formatter = EcsFormatter::Factory.build(data, **service_config)

    assert_instance_of EcsFormatter::Controller, formatter
  end

  def test_builds_activejob_for_perform_active_job
    data = { event_name: "perform.active_job" }
    formatter = EcsFormatter::Factory.build(data, **service_config)

    assert_instance_of EcsFormatter::ActiveJob, formatter
  end

  def test_builds_activejob_for_other_active_job_events
    data = { event_name: "perform_start.active_job" }
    formatter = EcsFormatter::Factory.build(data, **service_config)

    assert_instance_of EcsFormatter::ActiveJob, formatter
  end
end

class EcsFormatterControllerTest < Minitest::Test
  include EcsFormatterFixtures

  def test_complete_controller_log_structure
    formatter = EcsFormatter.new(**service_config)
    result = JSON.parse(formatter.call(controller_data))
    untestable_keys = ["@timestamp", "@version"] # Not worth the effort of testing for specific values

    assert untestable_keys.all? { result.key?(it) }

    expected = {
      "http" => {
        "request" => {
          "method" => "POST",
          "referrer" => "https://example.com/signup"
        },
        "response" => {
          "mime_type" => "json",
          "status_code" => 201
        }
      },
      "url" => {
        "path" => "/users/create",
        "original" => "https://api.example.com/users/create?source=web"
      },
      "event" => {
        "kind" => "event",
        "name" => "pippero",
        "duration" => 234560000 # 234.56ms in ns
      },
      "source" => {
        "ip" => "192.168.1.100"
      },
      "destination" => {
        "ip" => "10.0.0.1",
        "name" => "api.example.com"
      },
      "service" => {
        "name" => "test-app",
        "type" => "rails",
        "environment" => "test"
      },
      "rails" => {
        "controller" => "UsersController",
        "action" => "create",
        "params" => {
          "name" => "John",
          "email" => "john@example.com"
        },
        "view_runtime" => 78.90,
        "db_runtime" => 45.67
      }
    }

    assert_equal expected, result.reject { untestable_keys.include?(it) }
  end

  def test_controller_with_error
    formatter = EcsFormatter.new(**service_config)
    result = JSON.parse(formatter.call(controller_data_with_error))

    assert_equal "StandardError", result["error"]["type"]
    assert_equal "Database connection failed", result["error"]["message"]
    assert_includes result["error"]["stack_trace"], "/app/models/user.rb:42"
    assert_includes result["error"]["stack_trace"], "/app/controllers/users_controller.rb:15"
  end

  def test_controller_with_custom_payload
    formatter = EcsFormatter.new(**service_config)
    result = JSON.parse(formatter.call(controller_data_with_custom_payload))

    assert_equal 123, result["user"]["id"]
    assert_equal "test@example.com", result["user"]["email"]
    assert_equal "abc-123-def-456", result["trace"]["id"]
  end

  def test_nanoseconds_conversion_resilient_to_with_nil
    formatter = EcsFormatter.new(**service_config)
    data = controller_data
    data.delete(:duration)
    result = JSON.parse(formatter.call(data))

    assert_nil result["event"]["duration"]
  end
end

class EcsFormatterActiveJobTest < Minitest::Test
  include EcsFormatterFixtures

  def test_complete_activejob_log_structure
    formatter = EcsFormatter.new(**service_config)
    result = JSON.parse(formatter.call(activejob_data))
    untestable_keys = ["@timestamp", "@version"] # Not worth the effort of testing for specific values

    assert untestable_keys.all? { result.key?(it) }

    expected = {
      "event" => {
        "kind" => "event",
        "name" => "perform_start.active_job",
        "duration" => 2500750000 # 2500.75ms in ns
      },
      "service" => {
        "name" => "test-app",
        "type" => "rails",
        "environment" => "test"
      },
      "job" => {
        "job_class" => "EmailNotificationJob",
        "job_id" => "job-abc-def-123",
        "adapter_class" => "ActiveJob::QueueAdapters::SidekiqAdapter",
        "queue_name" => "mailers",
        "args" => ["positional", { "user_id" => 42, "template" => "welcome" }]
      }
    }

    assert_equal expected, result.reject { untestable_keys.include?(it) }
  end

  def test_cleaned_args_removes_aj_ruby2_keywords
    formatter = EcsFormatter.new(**service_config)
    result = JSON.parse(formatter.call(activejob_data_with_ruby2_keywords))

    assert_equal [{"report_id" => 999, "format" => "pdf"}], result["job"]["args"]
  end

  def test_activejob_with_error
    formatter = EcsFormatter.new(**service_config)
    result = JSON.parse(formatter.call(activejob_data_with_error))

    assert_equal "RuntimeError", result["error"]["type"]
    assert_equal "Job processing failed", result["error"]["message"]
    assert_includes result["error"]["stack_trace"], "/app/jobs/email_job.rb:20"
  end

  def test_activejob_with_custom_payload
    formatter = EcsFormatter.new(**service_config)
    result = JSON.parse(formatter.call(activejob_data_with_custom_payload))

    assert_equal "high", result["job"]["priority"]
    assert_equal 2, result["job"]["retry_count"]
  end

  def test_event_duration_converted_to_nanoseconds
    formatter = EcsFormatter.new(**service_config)
    data = activejob_data.merge(duration: 1234.56)
    result = JSON.parse(formatter.call(data))

    assert_equal 1234560000, result["event"]["duration"]
  end

  def test_exception_without_backtrace
    exception_obj = StandardError.new("Error without trace") # Don't set backtrace

    formatter = EcsFormatter.new(**service_config)
    data = activejob_data.merge(
      exception: ["StandardError", "Error without trace"],
      exception_object: exception_obj
    )
    result = JSON.parse(formatter.call(data))

    assert_equal "StandardError", result["error"]["type"]
    assert_equal "Error without trace", result["error"]["message"]
    # stack_trace will be nil and removed by deep_compact
    refute result["error"].key?("stack_trace")
  end
end
