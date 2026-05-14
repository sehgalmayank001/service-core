# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-05-14

### Added

- `ServiceCore::Response`: a Hash-compatible value object backing
  `service.response` / `service.output` and the return of `#call`. Adds
  named accessors (`response.status`, `response.data`, `response.message`,
  `response.errors`), Hash-style `[]` / `[]=` / `==`, `dig`, `fetch`,
  `each_pair`, and `as_json` / `to_json`. Callers that previously
  reached for `service.output[:key]` on the 0.1.0 Hash output continue
  to work unchanged.
- `service.response` as an alias for `service.output`.
- `ServiceCore::FieldSet`: an immutable snapshot for `service.fields`.
  Each declared symbol field is exposed as a real method (e.g.
  `service.fields.first_name`); call `to_h` for a plain Hash.
- `field` raises `ServiceCore::ReservedFieldName` when the declared name
  would shadow a ServiceCore method. The reserved names are `:call`,
  `:errors`, `:fields`, `:output`, `:perform` and `:response`. Previously
  these names silently overrode gem internals (most dangerously
  `:errors`, which broke `ActiveModel::Validations`).
- `ServiceCore::Error` hierarchy with concrete subclasses
  `ServiceCore::InvalidKey` (raised by `Response#[]` / `[]=` on a
  non-allowed key) and `ServiceCore::ReservedFieldName`. `Error` itself
  existed since 0.1.0 but was never raised; `rescue ServiceCore::Error`
  now actually catches things.
- Cross-Rails test matrix via `appraisal`: Rails 7.2, 8.0 and 8.1.
- CI matrix across Ruby 3.3, 3.4 and 4.0 (excluding Ruby 4.0 + Rails 7.2).

### Changed

- The mixin that provides `success_response`, `error_response` and
  `formatted_response` is renamed from `ServiceCore::Response` to
  `ServiceCore::Responder`. The `Response` name now refers to the value
  object; the `Responder` mixin is the builder. Both modules are internal
  implementation details consumed via `include ServiceCore`, so users
  who only ever `include ServiceCore` are unaffected. Anyone including
  `ServiceCore::Response` directly must switch to
  `include ServiceCore::Responder`.
- Gemspec: `required_ruby_version` raised to `>= 3.1.0` (Ruby 2.7 and 3.0 are EOL).
- Gemspec: ActiveModel / ActiveSupport range widened to `>= 6.1, < 9.0`.
- RuboCop bumped to `~> 1.86` with `rubocop-rake` added as a plugin.
- Replaced `byebug` (unmaintained on Ruby 3+) with the stdlib `debug` gem.
- Removed `# frozen_string_literal: true` magic comments project-wide in
  favour of the project style; `VERSION` is now explicitly `.freeze`d.
- `add_error_and_validate` now forwards its `options` argument to
  `add_error` (and through to `ActiveModel::Errors#add`), matching its
  declared signature.
- Internal cleanups: `Output#initialize` now calls `super()`, the
  `StepValidation` validator helpers are private, and `auto_assign_status`
  no longer has the redundant elsif clauses.
- The class-level `fields_defined` registry is renamed to `field_names`
  and is now a `Set` of declared names rather than a Hash mapping names
  to defaults. Typed defaults are still applied through
  `ActiveModel::Attributes`; the old Hash was a Set with a confusing
  name and shape.
- `service.fields` no longer behaves like a Hash. The new `FieldSet`
  exposes named accessors plus `to_h`. Callers that did
  `service.fields[:name]` should use `service.fields.name`; iteration
  goes through `service.fields.to_h.each`.

### Fixed

- `Output#set_output` no longer drops legitimate falsy values. Previously
  `false`, `0`, and `""` were silently discarded; only `nil` is now skipped.
- `Responder#formatted_response` no longer gates its writes on
  ActiveSupport `present?`. `success_response(data: false)` now records
  `data: false`.
- `Base.field` no longer swallows positional defaults of `false` or `nil`.
  The arity of the positional arguments is used instead of `||`, so
  `field :enabled, :boolean, false` actually defaults to `false`.

## [0.1.0] - 2024-07-17

- Initial release.
