# ServiceCore

A tiny contract layer for Rails service objects: typed inputs, step validation, and predictable four-key responses.

ServiceCore gives Rails service objects a shared shape. Every service exposes a single call interface and returns the same response contract regardless of who wrote it.

This keeps controllers, jobs, and other callers from having to handle a different return style for every service object.

## Features

- Four-key response contract: `status`, `data`, `message`, and `errors`
- Field declarations with types, defaults, and ActiveModel validations
- Step-by-step validation that survives `valid?` calls
- Works on Ruby >= 3.1 and Rails / ActiveModel / ActiveSupport 6.1 through 8.x

## Background

ServiceCore follows the response shape described in

[The Shape of a Service Response](https://agnosticlogic.substack.com/p/the-shape-of-a-service-response).

## Installation

```sh
bundle add service_core
```

Or add it to your Gemfile:

```ruby
gem "service_core"
```

If you are not using Bundler:

```sh
gem install service_core
```

## The four-key response

Every service responds with at most four keys:

| Key       | Purpose                                                                |
| --------- | ---------------------------------------------------------------------- |
| `status`  | Machine-readable signal (`"success"`, `"error"`, or any custom state). |
| `data`    | The payload the caller asked for.                                      |
| `message` | High-level human context, distinct from per-field error detail.        |
| `errors`  | Structured error detail (Hash, Array, ActiveModel::Errors, ...).       |

The shape is enforced; the value types are not. Writing a key other than these four raises `ServiceCore::InvalidKey`.

## Defining a service

Include `ServiceCore` in your class and implement `perform`:

```ruby
class GreetService
  include ServiceCore

  field :first_name, :string
  field :last_name, :string
  field :active, :boolean, default: true

  def perform
    success_response(message: "Hello, World", data: full_name)
  end

  private

  def full_name
    "#{first_name} #{last_name}"
  end
end
```

## Calling a service

You can call a service either via `new(...).call` or via the `.call` shortcut on the class:

```ruby
response = GreetService.new(first_name: "John", last_name: "Doe").call
puts response
# => {status: "success", message: "Hello, World", data: "John Doe"}

service = GreetService.call(first_name: "John", last_name: "Doe")
service.response
# => {status: "success", message: "Hello, World", data: "John Doe"}
```

The instance method returns the response value object. The class-level `.call` returns the service instance, so you can also reach for `service.response` (or `service.output`, which is kept as an alias) after the fact.

## `Response`: the value object

`service.response` (and the value returned from `#call`) is a `ServiceCore::Response`. It exposes both named accessors and Hash-style access, and serialises to JSON like the underlying hash:

```ruby
response = GreetService.call(first_name: "John", last_name: "Doe").response

response.status   # => "success"
response.data     # => "John Doe"
response[:status] # => "success"
response == { status: "success", message: "Hello, World", data: "John Doe" } # => true
response.to_json  # => '{"status":"success","message":"Hello, World","data":"John Doe"}'
```

Writing or reading a key other than the four allowed raises `ServiceCore::InvalidKey`.

## Declaring fields

`field` supports both typed and untyped declarations.

```ruby
class MyService
  include ServiceCore

  field :first_name, :string                  # typed (ActiveModel::Attributes)
  field :active, :boolean, default: true      # typed with keyword default
  field :enabled, :boolean, false             # typed with positional default
  field :payload                              # untyped, can be any object/hash/array
end
```

Typed fields are backed by `ActiveModel::Attributes` and inherit its casting and default support.

The following names are reserved and cannot be used as field names because they would shadow methods the gem itself defines: `:call`, `:errors`, `:fields`, `:output`, `:perform`, `:response`. Declaring `field :errors` (for example) raises `ServiceCore::ReservedFieldName`.

### Field snapshot via `FieldSet`

After construction, `service.fields` exposes an immutable snapshot of the declared fields and their values as a `ServiceCore::FieldSet`. Each declared symbol field is available as a real method; call `to_h` if you need a plain Hash.

```ruby
service = GreetService.new(first_name: "John", last_name: "Doe")

service.fields.first_name   # => "John"
service.fields.to_h         # => { first_name: "John", last_name: "Doe", active: true }
```

The snapshot is taken at `#initialize`, so it reflects the values at construction time. Live values are still available through each declared accessor (e.g. `service.first_name`).

## Building responses

Three helpers cover almost every case.

### `success_response`

```ruby
def perform
  success_response(message: "Hello, World", data: full_name)
end
# => {status: "success", message: "Hello, World", data: "John Doe"}
```

Accepts `message` and `data`. Status is set to `"success"`.

### `error_response`

```ruby
def perform
  error_response(message: "validation failure", errors: "last_name can't be blank")
end
# => {status: "error", message: "validation failure", errors: "last_name can't be blank"}
```

Accepts `message` and `errors`. Status is set to `"error"`. `errors` can be a String, Hash, Array, or `ActiveModel::Errors` (which is normalised through `messages`).

### `formatted_response`

For any status that isn't success or error.

```ruby
def perform
  formatted_response(status: "processed", message: "Already done", data: existing_record)
end
# => {status: "processed", message: "Already done", data: ...}
```

Accepts `status`, `message`, `data`, and `errors`. Use this for `"pending"`, `"queued"`, `"processed"`, or any domain-specific status.

### `set_output`

For finer-grained control, write a single key at a time:

```ruby
def perform
  set_output(:message, "Hello, World")
  set_output(:data, full_name)
end
```

If `status` is not set explicitly, it is auto-assigned to `"success"` when `errors` is blank, and `"error"` otherwise. `nil` is the only value treated as "not set"; `false`, `0`, and `""` are stored as-is.

## Validations

Standard ActiveModel validations run before `perform`. If they fail, the response is filled in for you.

```ruby
class MyService
  include ServiceCore

  field :name, :string
  validates :name, presence: true

  def perform
    success_response(message: "Hello, World", data: name)
  end
end

MyService.new(name: "").call
# => {status: "error", message: "validation failure", errors: {name: ["can't be blank"]}}
```

### Step validation

When the result of one step decides the next, `add_error_and_validate` lets you accumulate errors mid-`perform` without `valid?` wiping them.

```ruby
class MyService
  include ServiceCore

  field :first_name, :string
  field :last_name, :string

  validates :first_name, presence: true

  def perform
    if last_name.blank?
      add_error_and_validate(:last_name, "can't be nil")
      return error_response(message: "validation failure", errors: errors)
    end

    success_response(data: { user: { id: 1 } })
  end
end

MyService.call(first_name: "abc").response
# => {status: "error", message: "validation failure", errors: {last_name: ["can't be nil"]}}
```

`add_error_and_validate(attribute, message, options = {})` forwards `options` to `ActiveModel::Errors#add`, so options like `strict: true` are honoured.

## Logging errors

`log_error(exception)` writes through the configured `ServiceCore.logger` and tags the message with the service class name.

```ruby
class MyService
  include ServiceCore

  field :name, :string

  def perform
    raise StandardError, "Something went wrong"
  rescue StandardError => e
    log_error(e)
    error_response(message: "Failed", errors: { base: [e.message] })
  end
end
```

## Exceptions

All gem-specific exceptions inherit from `ServiceCore::Error`, so a single rescue block can catch anything ServiceCore raises:

```ruby
begin
  MyService.call(...)
rescue ServiceCore::Error => e
  # any gem-raised error
end
```

The current concrete subclasses are:

- `ServiceCore::InvalidKey` — raised by `response[:not_allowed]` or `response[:not_allowed] = value` when the key is not one of the four allowed response keys.
- `ServiceCore::ReservedFieldName` — raised by `field :errors` (or any other reserved name) at class-definition time.

Two raises stay on stdlib classes: `Response#fetch` raises `KeyError` to match `Hash#fetch`, and the default `perform` raises `StandardError` until the service overrides it.

## Configuration

```ruby
ServiceCore.configure do |config|
  config.logger = Logger.new($stdout)
end
```

If you do not configure a logger, `ServiceCore.logger` defaults to `Rails.logger` when available, and otherwise to an `ActiveSupport::Logger` writing to `$stdout`.

## Stability

ServiceCore follows [Semantic Versioning](https://semver.org/). Starting with 1.0.0, the following are part of the public API and changes to them require a major version bump:

- The four-key response contract (`status`, `data`, `message`, `errors`).
- The Hash-compatible surface of `ServiceCore::Response` (`[]`, `[]=`, `==`, `to_h`, `to_s`, `inspect`, `keys`, `values`, `each`, `dig`, `fetch`, `key?` / `has_key?` / `include?`, `as_json`, `to_json`) and its named accessors (`status`, `data`, `message`, `errors`).
- The `ServiceCore::FieldSet` API (`to_h` and named accessors per declared symbol field).
- The service DSL: `include ServiceCore`, `field`, `validates`, `perform`, instance `#call` and class `.call`, `service.fields`, `service.response` / `service.output`.
- The response builders: `success_response`, `error_response`, `formatted_response`, `set_output`.
- The step-validation helpers: `add_error`, `add_error_and_validate`.
- The reserved field names: `:call`, `:errors`, `:fields`, `:output`, `:perform`, `:response`.
- The exception hierarchy under `ServiceCore::Error`.
- `ServiceCore.logger` and `ServiceCore.configure`.

The internals of `ServiceCore::Output`, the `Responder` mixin shape, and anything not listed above are implementation details and may change between any release.

## Compatibility

- Ruby: 3.1 minimum; tested against 3.3 and 3.4 (and 4.0 against Rails 8.x).
- ActiveModel / ActiveSupport: `>= 6.1, < 9.0`; tested against Rails 7.2, 8.0, and 8.1 via [appraisal](https://github.com/thoughtbot/appraisal).

## Development

```sh
bin/setup
bundle exec rspec
bundle exec rubocop
```

To run the spec suite against every supported Rails version:

```sh
bundle exec appraisal install
bundle exec appraisal rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [github.com/sehgalmayank001/service-core](https://github.com/sehgalmayank001/service-core). This project follows the [Contributor Covenant code of conduct](https://github.com/sehgalmayank001/service-core/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
