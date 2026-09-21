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

- [x] **Resolve the import-convention contradiction.** CLAUDE.md said use
      relative imports within a feature; `analysis_options.yaml` enforces
      `always_use_package_imports: true` / `prefer_relative_imports: false`.
      Since all 77 same-feature imports already followed the linter (and
      rewriting them to relative would fail `dart analyze`), updated
      CLAUDE.md's "## Imports" section to match the enforced rule instead.
- [x] **Move `features/navigation/` into `common_widgets/`.** Moved
      `main_bottom_nav_bar.dart` from `features/navigation/presentation/` to
      `common_widgets/` and updated the one import site (`app_router.dart`);
      removed the now-empty `features/navigation/` folder.
- [x] **`home/`, `timer/`, `profile/` are placeholder features** with no
      data/domain layers and aren't part of the documented feature list.
      Added a doc comment to `timer_screen.dart` and `profile_screen.dart`
      (matching `home_screen.dart`'s existing one) flagging them as
      placeholders needing real data/domain layers before being built out.

## Carried over from the Supabase migrations baseline plan

- [x] Get the live schema under version control. Recovered from
      `supabase_migrations.schema_migrations` (the real applied SQL, not a
      `supabase db pull` snapshot) into `supabase/migrations/`.
- [ ] Fix the anon-exploitable `SECURITY DEFINER` RPCs found by the security
      advisor during that work: `complete_task`, `uncomplete_task`,
      `get_daily_performance`, `get_streak`, `get_leaderboard`,
      `lock_expired_tasks`, `handle_new_user`, `handle_group_created` are all
      callable by `anon`/`authenticated` without checking `auth.uid()`
      against the caller-supplied user id.
- [ ] Minor: `generate_template_instances` is documented in
      `docs/database_schema.md` and cron-scheduled, but was never actually
      deployed — its nightly cron job has been failing since at least
      2026-09-17. No app consumer uses `task_templates` yet, so this is
      inert; fix if/when that feature gets built.

## Carried over from the earlier code review

- [ ] Replace (or clearly relabel) the fake "AI suggestions" in
      `create_task_sheet.dart` — currently `Random()`, not real AI. High risk
      given the JD's "AI-First Development" requirement.
- [x] Add a CI workflow (GitHub Actions: pub get, build_runner, analyze, test).
      Done: `.github/workflows/ci.yml` runs get/build_runner/format_check/
      analyze/test with coverage collection; branch protection requires it.
- [ ] Optional: add an `AnalyticsService` stub / Sentry wiring for a couple of
      key events (JD mentions Sentry, Amplitude/Braze, "measure what you ship").
- [ ] Minor: `Category.color` hex is fetched from Supabase but never rendered
      anywhere in the UI.
- [ ] Minor: `app_button.dart` defines `AppPrimaryButton`/`AppOutlineButton` —
      no class matches the filename, a small drift from the naming convention
      table.
