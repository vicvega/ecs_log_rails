# Elastic Common Schema for rails' logs
[![Gem Version](https://badge.fury.io/rb/ecs_log_rails.svg)](https://badge.fury.io/rb/ecs_log_rails)

`Ecs_log_rails` convert rails' multi line log into a file where each line is a JSON compliant with [Elastic Common Schema](https://www.elastic.co/guide/en/ecs/current/index.html)

Here is a basic example:
```
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

```
{"http":{"request":{"method":"GET","referrer":"http://localhost:3000/home/test1"},"response":{"mime_type":"html","status_code":200}},"url":{"path":"/home/test2","original":"http://localhost:3000/home/test2"},"event":{"kind":"event","duration":17400000},"source":{"ip":"127.0.0.1"},"destination":{"ip":"127.0.0.1","name":"localhost"},"service":{"name":"ecs-test","type":"rails","environment":"development"},"rails":{"controller":"HomeController","action":"test2","view_runtime":15.89,"db_runtime":1.21},"user":{"name":"test","email":"john@foo.bar","full_name":"John Doe","roles":["admin"]},"@timestamp":"2023-05-31T12:51:25.618Z","@version":"1"}
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Enjoy! 🍺🍺
