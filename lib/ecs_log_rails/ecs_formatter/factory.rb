class EcsFormatter
  class Factory
    private_class_method :new

    def self.build(data, **kwargs)
      # We support active job events as reported by lograge_activejob gem.
      # Being this the only specific data we currently support, everything else
      # is considered a controller's log event.
      if data[:event_name]&.match? %r(.active_job$)
        ActiveJob.new(data, **kwargs)
      else
        Controller.new(data, **kwargs)
      end
    end
  end
end
