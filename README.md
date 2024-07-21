# ServiceCore

ServiceCore provides a standardized way to define and use service objects in Ruby and Rails applications. It includes support for specifying fields, validations, responses, and error logging. This approach is inspired by the DRY (Don't Repeat Yourself) principle and Rails' convention over configuration philosophy.

## Installation
Install the gem and add to the application's Gemfile by executing:

```sh
bundle add service_core
```
Or in your Gemfile:

```ruby
gem "service_core"
```

If the bundler is not being used to manage dependencies, install the gem by executing:

```sh
gem install service_core
```

### Service Response Structure
The idea is to define a convention that the response from a service can have only four keys:
- status
- data
- message
- errors

The data type of any of the above keys is not enforced, giving the developer flexibility to return based on the use case, but should follow this response structure.
## Usage

### Defining a Service

To define a new service, include the `ServiceCore` module in your service class and define your fields and the `perform` method.
```ruby
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

The `call` method can be invoked on the service class and it too will return the object of the service.
```ruby
obj = MyService.call(first_name: "John", last_name: "Doe")
puts obj.output
# Output:
# {
#   status: "success",
#   message: "Hello, World",
#.  data: "John Doe"
# }
```

### `field` method
The `field` method can define primitive types and objects, like hash/array or any object. For objects, there is no need to declare the datatype.
```ruby
class MyService
  include ServiceCore

  field :first_name, :string
  field :last_name, :string
  field :payload # can be object/hash/array

  def perform
    success_response(message: "Hello, World", data: name)
  end

  def name
    "#{first_name} #{last_name}"
  end
end
```

### `set_output` method

The `set_output` method provides a way to set output of a specific key. It is the method used by the response_setters to set specific output value
```ruby
class MyService
  include ServiceCore

  field :first_name, :string
  field :last_name, :string
  field :payload # can be object/hash/array

  def perform
    set_output :message, "Hello, World"
    set_output :data, name
  end

  def name
    "#{first_name} #{last_name}"
  end
end

obj = MyService.call(first_name: "John", last_name: "Doe")
puts obj.output
# Output:
# {
#   status: "success",
#   message: "Hello, World",
#.  data: "John Doe"
# }
```
*NOTE:* If `:status` is not explicitly set in the perform method, the `success` status is returned if `errors` are blank else the `error` status is returned.

### Response Setters

#### `success_response`
Use the `success_response` method to return the `success` status, `data` and `message`
```ruby

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

service = MyService.new(first_name: "John", last_name: "Doe")
result = service.call
puts result
# Output:
# {
#   status: "success",
#   message: "Hello, World",
#.  data: "John Doe"
# }
```

`success_response` accepts following arguments:
- message
- data

#### `error_response`
Use the `error_response` method to return the `error` status, `errors` and `message`
```ruby

class MyService
  include ServiceCore

  field :first_name, :string
  field :last_name, :string
  field :active, :boolean, default: true

  def perform
    error_response(message: "validation failure", errors: "last_name can't be blank")
  end

  def name
    "#{first_name} #{last_name}"
  end
end

service = MyService.new(first_name: "John")
result = service.call
puts result
# Output:
# {
#   status: "error",
#   message: "validation failure",
#.  errors: "last_name can't be blank"
# }
```

`error_response` accepts following arguments:
- message
- errors

#### `formatted_response`
Use the `formatted_response` method to return any status other than `success` or `error`.
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

### Validations
Define validation on the service and those will be invoked before service logic is invoked.
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
Perform validation at each step of service logic. This is helpful when the result of the previous step decides the next logic.
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

obj = MyService.call(first_name: 'abc')
obj.output
# output:
# {
#   status: "error",
#   message: "validation failure",
#   errors: { last_name: ["can't be nil"] }
# }
```

### Logging Errors
Log errors using the `log_error` method.
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
Configure the logger for the ServiceCore module.
```ruby
ServiceCore.configure do |config|
  config.logger = Logger.new(STDOUT)
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sehgalmayank001/service-core. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/sehgalmayank001/service-core/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ServiceCore project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sehgalmayank001/service-core/blob/main/CODE_OF_CONDUCT.md).
