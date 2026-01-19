# frozen_string_literal: true

module EcsFormatterFixtures
  def service_config
    {
      service_name: "test-app",
      service_type: "rails",
      service_env: "test"
    }
  end

  def controller_data
    {
      method: "POST",
      path: "/users/create",
      format: "json",
      controller: "UsersController",
      action: "create",
      status: 201,
      params: { name: "John", email: "john@example.com" },
      db: 45.67,
      view: 78.90,
      duration: 234.56,
      remote_ip: "192.168.1.100",
      ip: "10.0.0.1",
      host: "api.example.com",
      referrer: "https://example.com/signup",
      original_url: "https://api.example.com/users/create?source=web",
      event_name: "pippero"
    }
  end

  def controller_data_with_error
    exception_obj = StandardError.new("Database connection failed")
    exception_obj.set_backtrace([
      "/app/models/user.rb:42:in `create'",
      "/app/controllers/users_controller.rb:15:in `create_action'"
    ])

    {
      method: "POST",
      path: "/users/create",
      status: 500,
      duration: 100.0,
      exception: ["StandardError", "Database connection failed"],
      exception_object: exception_obj
    }
  end

  def controller_data_with_custom_payload
    {
      method: "GET",
      path: "/users/profile",
      status: 200,
      duration: 50.0,
      ecs_custom: {
        user: {
          id: 123,
          email: "test@example.com"
        },
        trace: {
          id: "abc-123-def-456"
        }
      }
    }
  end

  # ActiveJob Fixtures

  def activejob_data
    {
      event_name: "perform_start.active_job",
      job_class: "EmailNotificationJob",
      job_id: "job-abc-def-123",
      adapter_class: "ActiveJob::QueueAdapters::SidekiqAdapter",
      queue_name: "mailers",
      args: [
        "positional",
        { user_id: 42, template: "welcome" }
      ],
      duration: 2500.75
    }
  end

  def activejob_data_with_ruby2_keywords
    {
      event_name: "enqueue.active_job",
      job_class: "ReportGeneratorJob",
      job_id: "job-xyz-789",
      args: [
        {
          "_aj_ruby2_keywords" => ["key1", "key2"],
          "report_id" => 999,
          "format" => "pdf"
        }
      ],
      duration: 50.0
    }
  end

  def activejob_data_with_error
    exception_obj = RuntimeError.new("Job processing failed")
    exception_obj.set_backtrace([
      "/app/jobs/email_job.rb:20:in `perform'",
      "/gems/pippero/lib/active_job/execution.rb:48:in `perform'"
    ])

    {
      event_name: "perform.active_job",
      job_class: "EmailJob",
      job_id: "job-error-123",
      duration: 100.0,
      exception: ["RuntimeError", "Job processing failed"],
      exception_object: exception_obj
    }
  end

  def activejob_data_with_custom_payload
    {
      event_name: "perform.active_job",
      job_class: "DataProcessorJob",
      job_id: "job-custom-456",
      duration: 500.0,
      ecs_custom: {
        job: {
          priority: "high",
          retry_count: 2
        }
      }
    }
  end
end
