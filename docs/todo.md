# Engineering Todo

Tracking outstanding work from the architecture audit and the earlier code
review, in priority order. Check items off as they're completed.

## Critical

- [x] **Add an `AppUser` domain model.** `supabase_flutter`'s `User` type
      currently leaks out of `data/` through
      `auth/presentation/auth_state_provider.dart` (which imports
      `supabase_flutter` directly) and across the feature boundary into
      `tasks/presentation/task_mutation_controller.dart` and
      `task_create_controller.dart`, which both read `.id` off the raw SDK
      type. Add `auth/domain/app_user.dart`, map `User` → `AppUser` inside
      `SupabaseAuthRepository`, and change `AuthRepository` to expose
      `AppUser?` instead of `Session?`/`User?`.

## High

- [x] **Replace hardcoded color literals with `Theme.of(context).colorScheme`.**
      Found in `home_screen.dart`, `login_screen.dart`, `register_screen.dart`,
      `app_button.dart`, `app_text_field.dart`, `main_bottom_nav_bar.dart`.
      The `tasks` feature widgets do this correctly — use them as the
      reference.
- [x] **Stop rebuilding the entire `GoRouter` instance on every auth change.**
      `app_router.dart`'s `appRouterProvider` calls `ref.watch(authStateProvider)`
      inside its body, so Riverpod reconstructs the whole `GoRouter` (not just
      re-evaluates `redirect`) on every sign-in/sign-out/token refresh. Use a
      `GoRouterRefreshStream`-style `Listenable` instead, matching the
      Andrea Bizzotto reference architecture this project is based on.

## Medium

- [ ] **Resolve the import-convention contradiction.** CLAUDE.md says use
      relative imports within a feature; `analysis_options.yaml` enforces
      `always_use_package_imports: true` / `prefer_relative_imports: false`.
      All 77 same-feature imports in the codebase follow the linter, not the
      doc. Decide which is correct and align the other.
- [ ] **Move `features/navigation/` into `common_widgets/`.** The bottom nav
      bar is shared UI chrome, not a functional feature per the project's own
      definition ("what the user does").
- [ ] **`home/`, `timer/`, `profile/` are placeholder features** with no
      data/domain layers and aren't part of the documented feature list.
      Not wrong, just don't present them as finished — give them proper
      layers when actually built out.

## Carried over from the earlier code review

- [ ] Replace (or clearly relabel) the fake "AI suggestions" in
      `create_task_sheet.dart` — currently `Random()`, not real AI. High risk
      given the JD's "AI-First Development" requirement.
- [ ] Add a CI workflow (GitHub Actions: pub get, build_runner, analyze, test).
- [ ] Optional: add an `AnalyticsService` stub / Sentry wiring for a couple of
      key events (JD mentions Sentry, Amplitude/Braze, "measure what you ship").
- [ ] Minor: `Category.color` hex is fetched from Supabase but never rendered
      anywhere in the UI.
- [ ] Minor: `app_button.dart` defines `AppPrimaryButton`/`AppOutlineButton` —
      no class matches the filename, a small drift from the naming convention
      table.
