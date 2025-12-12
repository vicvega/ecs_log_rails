# Elastic Common Schema for rails' logs
[![Gem Version](https://badge.fury.io/rb/ecs_log_rails.svg)](https://badge.fury.io/rb/ecs_log_rails)
[![Actions Status: test](https://github.com/vicvega/ecs_log_rails/workflows/CI/badge.svg)](https://github.com/vicvega/ecs_log_rails/actions/workflows/ci.yml)


`ecs_log_rails` convert rails' multi line log into a file where each line is a JSON compliant with [Elastic Common Schema](https://www.elastic.co/guide/en/ecs/current/index.html)

Here is a basic example:

```json
{"http":{"request":{"method":"GET","referrer":"http://localhost:3000/home/test1"},"response":{"mime_type":"html","status_code":200}},"url":{"path":"/home/test5","original":"http://localhost:3000/home/test5"},"event":{"kind":"event","duration":263890000},"source":{"ip":"127.0.0.1"},"destination":{"ip":"127.0.0.1","name":"localhost"},"service":{"name":"ecs-test","type":"rails","environment":"development"},"rails":{"controller":"HomeController","action":"test5","view_runtime":259.27,"db_runtime":1.44},"@timestamp":"2023-05-31T12:05:19.517Z","@version":"1"}
{"http":{"request":{"method":"GET","referrer":"http://localhost:3000/home/test5"},"response":{"mime_type":"html","status_code":200}},"url":{"path":"/home/test1","original":"http://localhost:3000/home/test1"},"event":{"kind":"event","duration":274830000},"source":{"ip":"127.0.0.1"},"destination":{"ip":"127.0.0.1","name":"localhost"},"service":{"name":"ecs-test","type":"rails","environment":"development"},"rails":{"controller":"HomeController","action":"test1","view_runtime":270.57,"db_runtime":1.17},"@timestamp":"2023-05-31T12:41:57.536Z","@version":"1"}
```

It uses [`lograge`](https://github.com/roidrage/lograge/tree/master) under the hood

## Usage

Add in your `Gemfile`

```ruby
gem "ecs_log_rails"
```

Enable it setting `ecs_log_rails.enabled = true` in `config/application.rb`, or in a specific environment config file or even in an initializers

```ruby
# e.g. in config/environments/production.rb
Rails.application.configure do
  config.ecs_log_rails.enabled = true
end
```

## Advanced configuration

The following parameters are available
- `config.ecs_log_rails.enabled` to enable it (default: `false`)
- `config.ecs_log_rails.keep_original_rails_log` to keep original rails' log (default: `true`)
- `config.ecs_log_rails.log_level` to set log level (default: `:info`)
- `config.ecs_log_rails.log_file` to set the output file (default: `File.join("log", "ecs_log_rails.log")`)
- `config.ecs_log_rails.service_name` to set `service.name` field (default: Rails application name)
- `config.ecs_log_rails.service_env` to set `service.environment` field (default: `Rails.env`)
- `config.ecs_log_rails.service_type` to set `service.type` field (default: `rails`)

> [!NOTE]
> When `ecs_log_rails.enabled` is set to a *truish* value, it will underneath set `lograge.enable` to the same value.

You can also configure additional payload, using a hook to access controller methods

For example the following

```ruby
config.ecs_log_rails.custom_payload do |controller|
  if controller.respond_to?(:current_user)
    user = controller.current_user
    unless user.nil?
      {
        user: {
          name: user.username,
          email: user.email,
          full_name: user.fullname,
          roles: user.roles.map(&:name)
        }
      }
    end
  end
end
```
will add information on current user

```json
{"http":{"request":{"method":"GET","referrer":"http://localhost:3000/home/test1"},"response":{"mime_type":"html","status_code":200}},"url":{"path":"/home/test2","original":"http://localhost:3000/home/test2"},"event":{"kind":"event","duration":17400000},"source":{"ip":"127.0.0.1"},"destination":{"ip":"127.0.0.1","name":"localhost"},"service":{"name":"ecs-test","type":"rails","environment":"development"},"rails":{"controller":"HomeController","action":"test2","view_runtime":15.89,"db_runtime":1.21},"user":{"name":"test","email":"john@foo.bar","full_name":"John Doe","roles":["admin"]},"@timestamp":"2023-05-31T12:51:25.618Z","@version":"1"}
```

## ActiveJob integration

Add in your `Gemfile`

```ruby
gem "ecs_log_rails"
gem "lograge_activejob"
```

Order matters: `lograge_activejob` must be required **after** `ecs_log_rails`.
`ecs_log_rails` must be enabled or `lograge_activejob` won't activate itself.

Any custom `lograge_activejob` setup will be ignored.

ActiveJob logs will be added to the same output file with this structure:

```json
{"event":{"kind":"event","name":"perform.active_job","duration":5746640000},"service":{"name":"CoolApp","type":"rails","environment":"development"},"job":{"job_class":"GoodJob","job_id":"941febf4-24d6-4fc6-98b2-b7570fcf63cf","adapter_class":"AsyncAdapter","queue_name":"default","args":[{"command":"do_it","ids":[1]}]},"@timestamp":"2025-12-12T21:03:20.277Z","@version":"1"}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Enjoy! 🍺🍺
