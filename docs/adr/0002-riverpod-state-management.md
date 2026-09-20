# 0002. Riverpod (with code generation) as state management

## Context

The app needs to manage async data from Supabase (reads and writes),
reactive derived state (e.g. a task list scoped to the signed-in user and a
selected date), and local UI state, all while staying easy to test without a
real backend, since the repository pattern (see `docs/architecture.md`
Decision 2) depends on swapping in fakes.

## Decision

Riverpod, using `@riverpod` code generation exclusively. Never a manually
constructed `Provider`/`FutureProvider`/etc.

## Alternatives considered

- **BLoC**: more ceremony per feature (separate event/state/bloc classes)
  for what's mostly reactive-read-plus-CRUD-write state here. Ali used BLoC
  professionally at Enpal, but that's a resume line from the job, not a
  reason to bring it into this project.
- **Plain `provider` package**: no compile-time-checked provider identity,
  more runtime "provider not found" failure modes, and no built-in
  `family`/`autoDispose`/async primitives. Riverpod exists specifically to
  fix these gaps in `provider`.
- **Riverpod without code generation**: more boilerplate, and provider names
  become plain identifiers instead of generated, typo-resistant symbols.
  `CLAUDE.md` mandates codegen for exactly this reason.

## Consequences

- Every provider file needs `part 'x.g.dart'`, and `build_runner` must run
  before `analyze`/`test` see valid code, enforced in CI.
- Riverpod's major-version churn is a real, recurring cost: the 2.x to 3.x
  bump (`flutter_riverpod`/`riverpod_annotation`/`riverpod_generator`, done
  in [PR #13](https://github.com/Ali-Assi-1994/telos/pull/13)) removed the
  generated `XxxRef` typedefs, tightened disposed-provider checks, and
  changed default retry behavior, all real application-code fallout, not
  just a version bump. Accepted because Riverpod is actively maintained and
  matches production experience (Ali led the Riverpod transition at
  AlGooru).
- Every controller is testable against a fake repository via
  `ProviderContainer`/`ProviderScope` overrides, with zero network
  dependency; see `test/features/*/presentation/*_controller_test.dart`.
