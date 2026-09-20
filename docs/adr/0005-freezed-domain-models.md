# 0005. freezed for domain models

## Context

Domain models need immutability, value equality, and a safe way to derive a
modified copy of an existing instance (e.g. toggling `Task.completed`)
without hand-maintaining `==`, `hashCode`, and `copyWith` by hand for every
field as models grow. `Task` alone has around a dozen fields.

## Decision

`freezed` (plus `json_serializable` for `fromJson`/`toJson`) for every
domain model, generated via `@freezed` and code generation.

## Alternatives considered

- **Hand-written immutable classes**: correct in principle, but tedious and
  error-prone to keep `==`/`hashCode`/`copyWith` in sync as fields are
  added: a classic source of subtle bugs (a field silently missing from
  `copyWith`).
- **`equatable` alone**: gives value equality but not `copyWith` or JSON
  codegen; would still need a separate solution for both.
- **Plain Dart 3 classes with manually written `copyWith`**: viable for a
  model with two or three fields, but doesn't scale to `Task`'s field count
  without the same maintenance burden as the fully hand-written option.

## Consequences

- freezed's 2.x to 4.x major bump (landed in
  [PR #13](https://github.com/Ali-Assi-1994/telos/pull/13), alongside
  `freezed_annotation` 2.x to 3.x) required adding the `abstract` keyword to
  every `@freezed class` and dropped the generated `.map()`/`.when()`
  methods in favor of Dart's native `switch` pattern matching: a real,
  one-time migration cost, now paid and current.
- Generated `.g.dart`/`.freezed.dart` files are gitignored, not committed.
  That's a deliberate choice (see `CLAUDE.md`), so `build_runner` must run
  in CI before `analyze`/`test`, which it already does.
- Domain models stay pure Dart with zero Flutter/Supabase dependencies,
  importable by every layer (see `docs/architecture.md`, Section 2).
