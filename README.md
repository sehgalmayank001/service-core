# ServiceCore

ServiceCore provides a standardized way to define and use service objects in your Ruby and Rails applications. It includes support for defining fields, validations, responses, and logging.

## Installation
Install the gem and add to the application's Gemfile by executing:

```sh
bundle add service_core
```
If bundler is not being used to manage dependencies, install the gem by executing:

```sh
gem install service_core
```
## Usage

### Defining a Service

To define a new service, include the `ServiceCore` module in your service class and define your fields and the perform method.
```ruby
# app/services/my_service.rb

class MyService
  include ServiceCore

  field :first_name, :string
  field :last_name, :string
  field :active, :boolean, default: true

  def perform
    success_response(message: "Hello, World", data: name)
  end

  def name
    "#{first_name} #{last_name}"
  end
end
```

### Using a Service
Instantiate and call the service to execute it. The call method will validate the input, perform the operation, and return the output.
```ruby
service = MyService.new(first_name: "John", last_name: "Doe")
result = service.call
puts result
# Output:
# {
#   status: "success",
#   message: "Hello, World",
#.  data: "John Doe"
# }

puts service.output
# Output:
# {
#   status: "success",
#   message: "Hello, World",
#.  data: "John Doe"
# }
```

### Validations
You can define validation on the service and  those will be invoked before service logic is invoked
```ruby
class MyService
  include ServiceCore

  field :name, :string
  validates :name, presence: true

  def perform
    success_response(message: "Hello, World", data: name)
  end
end

service = MyService.new(name: "")
result = service.call
puts result
# Output:
#{
#   status: "error",
#   message: "validation failure",
#   errors: { name: ["can't be blank"] }
# }
```

### Step Validation
You can perform validation at each step of service logic. This is helpful when result of previous step decides next logic.
```ruby
class MyService
  include ServiceCore
  
  field :first_name, :string
  field :last_name, :string
  field :user

  validates :first_name, presence: true
  validates :user, presence: true

  def perform
    if last_name.blank?
      add_error_and_validate(:last_name, "can't be nil")
      return error_response(message: "validation failure", errors: errors)
    end
    
   success_response(data: { user: { id: 1 } })
  end
end

MyService.call(first_name: 'abc')
# output:
# {
#   status: "error",
#   message: "validation failure",
#   errors: { last_name: ["can't be nil"] }
# }
```

### Logging Errors
You can log errors using the `log_error` method.
```ruby
class MyService
  include ServiceCore

  field :name, :string

  def perform
    begin
      raise StandardError, "Something went wrong"
    rescue StandardError => e
      log_error(e)
      error_response(message: "Failed", errors: { base: [e.message] })
    end
  end
end

service = MyService.new(name: "World")
result = service.call
puts result
# Output:
# {
#   status: "error",
#   message: "Failed",
#   errors: { base: ["Something went wrong"] }
# }

```

### Configuring the Logger
You can configure the logger for the ServiceCore module.
```ruby
ServiceCore.configure do |config|
  config.logger = Logger.new(STDOUT)
end
```

### Custom Response
use `formatted_response` method to return any other status other than `success` or `error`
```ruby

class MyService
  include ServiceCore

  field :first_name, :string
  field :last_name, :string
  field :active, :boolean, default: true

  def perform
    formatted_response(status: 'processed', message: "Hello, World", data: name)
  end

  def name
    "#{first_name} #{last_name}"
  end
end

service = MyService.new(first_name: "John", last_name: "Doe")
result = service.call
puts result
# Output:
# {
#   status: "processed",
#   message: "Hello, World",
#.  data: "John Doe"
# }
```

`formatted_response` accepts following arguments:
- status
- message
- data
- errors

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sehgalmayank001/service-core. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/sehgalmayank001/service-core/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ServiceCore project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sehgalmayank001/service-core/blob/main/CODE_OF_CONDUCT.md).
