# Testing strategy

What's tested at each layer, how Riverpod overrides make it possible without
a real backend, and how to run each kind of test.

## Unit tests (`test/features/*/data/`)

Repository and DTO logic tested directly, with no Riverpod involved. See
`test/features/tasks/data/task_dto_test.dart` and
`supabase_task_repository_test.dart`.

```bash
make test
```

## Controller tests (`test/features/*/presentation/*_controller_test.dart`)

Controllers (`AsyncNotifier` subclasses) tested against a `ProviderContainer`
with the repository provider overridden by a fake
(`FakeAuthRepository`/`FakeTaskRepository` in `test/features/*/data/fakes/`).
No widget tree, no network.

A gotcha worth knowing: autoDispose controllers need an active listener to
survive across `await` gaps in Riverpod 3.x, matching what a real widget's
`ref.watch`/`ref.listen` would provide. Tests that call
`container.read(someControllerProvider.notifier).someMethod()` without first
calling `container.listen(someControllerProvider, (_, _) {})` can see the
controller torn down mid-mutation. See the `setUp` blocks in
`task_create_controller_test.dart` and `task_mutation_controller_test.dart`
for the pattern.

```bash
make test
```

## Widget tests (`test/features/*/presentation/*_screen_test.dart`)

Full screens pumped inside a `ProviderScope` with fake repositories,
verifying real widget behavior (form validation, tapping a task to complete
it, error states) without a device.

```bash
make test
```

## Integration tests (`integration_test/`)

Full app flows (`App()`, real `GoRouter` navigation, real animations) run on
a real simulator or emulator, still backed by fake repositories via
`ProviderScope` overrides rather than a live Supabase backend. Written with
[Patrol](https://patrol.leancode.co), chosen over plain `integration_test`
for native automation capability the app will need later (permission
dialogs, notifications) and because demonstrating Patrol experience is part
of the point of this repo.

**Version pinning matters.** `patrol_cli` must be a version compatible with
the `patrol` package pinned in `pubspec.yaml` (currently `4.8.0`) — they are
not interchangeable across versions, and installing "whatever's latest" for
one half will silently produce a test run that builds successfully but
discovers zero tests. `patrol_cli`'s own `patrol test` command detects this
and tells you the exact fix. As of this writing, `patrol` `4.8.0` pairs with
`patrol_cli` `4.6.1`:

```bash
dart pub global activate patrol_cli 4.6.1
```

Run all integration tests on a booted iOS Simulator or Android
emulator/device:

```bash
patrol test -d "<device name, e.g. iPhone 16e, or emulator-5554>"
```

Or a single file:

```bash
patrol test --target integration_test/sign_in_flow_test.dart -d "<device>"
```

### Native setup this required

Both platforms needed a one-time native bridge in addition to the
`patrol`/`patrol_cli` install, since Patrol's Dart tests run inside a native
instrumentation test:

- **iOS**: an `RunnerUITests` XCUITest target (`ios/RunnerUITests/
  RunnerUITests.m`), added to the `Runner` scheme's `TestAction`, linked
  against the `FlutterGeneratedPluginSwiftPackage` Swift package (the same
  one `Runner` itself uses — Patrol's native code ships as a Flutter plugin,
  and Swift Package Manager dependencies aren't inherited across Xcode
  targets the way CocoaPods ones are), and added to `ios/Podfile` as
  `target 'RunnerUITests' do inherit! :complete end`.
- **Android**: `android/app/src/androidTest/java/com/example/telos/
  MainActivityTest.java`, `testInstrumentationRunner =
  "pl.leancode.patrol.PatrolJUnitRunner"` and the AndroidX Test Orchestrator
  (`testOptions.execution`, `androidTestUtil("androidx.test:orchestrator")`)
  in `android/app/build.gradle.kts`.

### Not yet done

These integration tests only run locally today; they are not wired into CI
(`.github/workflows/ci.yml` runs `analyze`/`test`, neither of which touches
`integration_test/`). Running them in CI needs a macOS runner for iOS and an
emulator action (e.g. `reactivecircus/android-emulator-runner`) for Android —
tracked as follow-up work, not done here.
