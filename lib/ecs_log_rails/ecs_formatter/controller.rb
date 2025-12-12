class EcsFormatter
  class Controller
    include EcsGenerator

    def generate_ecs
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

    private

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

    def add_rails
      ecs_add(:rails, {
        controller: data[:controller],
        action: data[:action],
        params: data[:params],
        view_runtime: data[:view],
        db_runtime: data[:db]
      })
    end
  end
end
