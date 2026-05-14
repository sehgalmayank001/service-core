# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-05-14

### Added

- `ServiceCore::Response`: a Hash-compatible value object that backs
  `service.response` / `service.output` and the return of `#call`. Adds named
  accessors (`response.status`, `response.data`, `response.message`,
  `response.errors`), pattern matching via `deconstruct_keys`, `dig`, `fetch`,
  `each_pair`, and `as_json`/`to_json`. Existing `response[:status]`,
  `response == hash`, and `puts response` callers keep working unchanged
  because the value object is Hash-compatible.
- `service.response` as an alias for `service.output`. `output` is retained
  for backward compatibility.
- `ServiceCore::FieldSet`: an immutable snapshot for `service.fields`.
  Each declared symbol field is exposed as a real method (e.g.
  `service.fields.first_name`); call `to_h` for a plain Hash. The
  underlying hash is frozen.
- `field` now accepts positional defaults of any value, including `false`,
  `nil`, `0`, and `""`. The keyword form is unchanged.
- `field` raises `ArgumentError` when the declared name would shadow a
  ServiceCore method. The reserved names are `:call`, `:errors`, `:fields`,
  `:output`, `:perform` and `:response`. Previously these names silently
  overrode gem internals (most dangerously `:errors`, which broke
  `ActiveModel::Validations`).
- Cross-Rails test matrix using `appraisal`: Rails 7.2, 8.0 and 8.1.
- CI matrix expanded to Ruby 3.3, 3.4 and 4.0 (excluding Ruby 4.0 + Rails 7.2).
- This `CHANGELOG.md` is now structured per Keep a Changelog.
- Gem-specific exception hierarchy under `ServiceCore::Error`. Concrete
  subclasses: `ServiceCore::InvalidKey` (raised by `Response#[]` / `[]=`
  on a non-allowed key) and `ServiceCore::ReservedFieldName` (raised by
  `field` when a reserved name is declared). `ServiceCore::Error`
  itself existed since 0.1.0 but was never raised. Callers can now
  `rescue ServiceCore::Error => e` to catch any gem-raised error.

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
  and is now a `Set` of declared field names rather than a Hash mapping
  names to defaults. The default values were never read (they remain in
  effect through `ActiveModel::Attributes`); the Hash had degenerated
  into a set-of-names with a confusing name and shape.
- `service.fields` no longer behaves like a Hash. The previous Hash gave
  free `[]`, `each`, `keys`, `values`, etc.; the new `FieldSet` deliberately
  exposes only named accessors plus `to_h`. Callers that did
  `service.fields[:name]` should use `service.fields.name`; callers that
  iterated should call `service.fields.to_h.each`. The 0.1.0 README did
  not document any Hash semantics on `service.fields`, but the type change
  is worth calling out explicitly.

### Fixed

- `Output#set_output` no longer drops legitimate falsy values. Previously
  `false`, `0`, and `""` were silently discarded; only `nil` is now skipped.
- `Responder#formatted_response` no longer gates its writes on
  ActiveSupport `present?`. Same falsy-value preservation applies, so
  `success_response(data: false)` records `data: false`.
- `Base.field` no longer swallows positional defaults of `false` or `nil`.
  The arity of the positional arguments is used instead of `||`, so a
  `field :enabled, :boolean, false` declaration now actually defaults
  to `false`.
- `response.rb` and `field_set.rb` now explicitly require the
  ActiveModel/ActiveSupport pieces they depend on, instead of relying on
  transitive autoloading from elsewhere in the gem.
- `Response#dig` returns `nil` for unknown root keys (matching `Hash#dig`)
  instead of raising `ArgumentError`. `Response#fetch` raises `KeyError`
  for unknown keys (matching `Hash#fetch`) instead of `ArgumentError`,
  and now uses a sentinel default so passing extra positional arguments
  raises like `Hash#fetch` does. Writes (`[]`, `[]=`) still police the
  four-key contract.

## [0.1.0] - 2024-07-17

- Initial release.
