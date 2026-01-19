class EcsFormatter
  class ActiveJob
    include EcsGenerator

    def generate_ecs
      add_event
      add_service
      add_active_job
      add_error
      add_custom_payload
    end

    private

    def add_active_job
      ecs_add(:job, {
        job_class: data[:job_class],
        job_id: data[:job_id],
        adapter_class: data[:adapter_class],
        queue_name: data[:queue_name],
        args: cleaned_active_job_args
      })
    end

    def cleaned_active_job_args
      args = data[:args]
      return args unless args.is_a?(Array)

      args.map do |arg|
        next arg if !arg.is_a?(Hash)
        next arg if !arg.key?("_aj_ruby2_keywords")

        arg.delete("_aj_ruby2_keywords")

        arg
      end
    end
  end
end
