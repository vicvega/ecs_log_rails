require "./lib/ecs_log_rails/version"

Gem::Specification.new do |s|
  s.name = "ecs_log_rails"
  s.version = EcsLogRails::VERSION
  s.summary = "Elastic Common Schema for rails' logs"
  s.description = "Convert rails' multi-line logging into a single line JSON formatted ECS compliant"
  s.authors = ["Francesco Coda Zabetta"]
  s.email = "francesco.codazabetta@gmail.com"
  s.files = ["lib/ecs_log_rails.rb"]
  s.homepage =
    "https://rubygems.org/gems/hola"
  s.license = "MIT"

  s.add_runtime_dependency "lograge"
  s.add_runtime_dependency "logstash-event"
end
