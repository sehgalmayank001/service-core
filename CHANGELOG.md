# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `ServiceCore::Result`: a Hash-compatible value object that backs `service.output`
  and the return of `#call`. Adds named accessors (`result.status`, `result.data`,
  `result.message`, `result.errors`), pattern matching via `deconstruct_keys`,
  `dig`, `fetch`, `each_pair`, `as_json`/`to_json`, and a `.from` Hash coercer.
  Existing `result[:status]`, `result == hash`, and `puts result` callers keep
  working unchanged.
- `ServiceCore::FieldSet`: an immutable, Hash-compatible snapshot for
  `service.fields`. Each declared symbol field is also exposed as a real
  method (e.g. `service.fields.first_name`), and the underlying hash is
  frozen.
- `field` now accepts positional defaults of any value, including `false`,
  `nil`, `0`, and `""`. The keyword form is unchanged.
- Cross-Rails test matrix using `appraisal`: Rails 7.2, 8.0 and 8.1.
- CI matrix expanded to Ruby 3.3, 3.4 and 4.0 (excluding Ruby 4.0 + Rails 7.2).
- This `CHANGELOG.md` is now structured per Keep a Changelog.

### Changed

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

### Fixed

- `Output#set_output` no longer drops legitimate falsy values. Previously
  `false`, `0`, and `""` were silently discarded; only `nil` is now skipped.
- `Response#formatted_response` no longer gates its writes on
  ActiveSupport `present?`. Same falsy-value preservation applies, so
  `success_response(data: false)` records `data: false`.
- `Base.field` no longer swallows positional defaults of `false` or `nil`.
  The arity of the positional arguments is used instead of `||`, so a
  `field :enabled, :boolean, false` declaration now actually defaults
  to `false`.
- `response.rb` and `field_set.rb` now explicitly require the
  ActiveModel/ActiveSupport pieces they depend on, instead of relying on
  transitive autoloading from elsewhere in the gem.

## [0.1.0] - 2024-07-17

- Initial release.
