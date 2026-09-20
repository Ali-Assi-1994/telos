# Evidence Gap Report

Audit of the repo against `Telos Evidence Plan (for Claude Code)`, the companion
plan Ali shared. That plan was written from the README alone. This report
checks its claims and "verify" items against the actual code, so decisions
about what to build next are based on what is really here.

Date: 2026-09-20 (updated same day after PR #12, #13, and Dependabot triage).

## 0. Headline correction

The plan assumes a more finished product than exists. Before any evidence
work (CI, tests, ADRs) compounds on top of the app, it is worth naming this
plainly:

- Of the five features the project's own architecture targets (`auth`,
  `tasks`, `performance`, `groups`, `leaderboard`), only **`auth` and `tasks`**
  have real `data/`/`domain/` layers. `home/`, `profile/`, `timer/` are
  presentation-only placeholders, already flagged as such in
  `docs/todo.md`.
- There is **no `supabase/` directory anywhere in the repo**: no migrations,
  no RLS policies, no Edge Functions, no seed data. `docs/database_schema.md`
  and `docs/architecture.md` describe a schema, RPCs, Edge Functions and
  pg_cron jobs in prose, none of which exist as executable code in git.
- Zero `.rpc()` calls exist in `lib/` today, despite the architecture doc
  and this project's `CLAUDE.md` both mandating RPC for atomic operations.

This does not invalidate the plan. It changes the order: several "P2 depth"
items (Supabase RLS, RPC-backed writes) are really **prerequisites** the repo
is missing outright, not verify-then-polish items.

## 1. Hard constraints (Section 1 of the plan)

| Constraint | Status | Evidence |
|---|---|---|
| Keep core stack (Riverpod+codegen, GoRouter, Supabase, freezed, feature-first) | DONE | `pubspec.yaml`, `lib/src/features/*`. Stack unchanged in kind; versions modernized (Riverpod 2.x to 3.x, freezed 2.x to 4.x, go_router 14.x to 18.x, Flutter SDK 3.41.0 to 3.47.5) — see Section 3a. |
| No em dash anywhere | PARTIAL | `README.md` clean. `CLAUDE.md` and `docs/architecture.md` already contain em dashes (pre-existing, not written under this plan). Worth a cleanup pass if the rule is meant to apply repo-wide, not just to new docs. |
| No secrets / real personal data | DONE (as far as verifiable) | Only `.env.dev`, `.env.example` at root; `.env.dev` is presumably gitignored (see P1.3 note below to confirm) |

## 2. Section 3 claims ("what the README already shows")

| Claim | Status | Evidence |
|---|---|---|
| Feature-first architecture with linked `docs/architecture.md` | DONE | `docs/architecture.md` exists, 23KB, ToC covers 10 sections |
| Riverpod codegen | DONE | `riverpod_annotation` + `riverpod_generator` in `pubspec.yaml`/`pubspec.lock` |
| GoRouter | DONE | `go_router ^14.2.0` |
| freezed models | DONE | `freezed`, `freezed_annotation`, `json_serializable` present |
| Makefile with analyze/test/codegen targets | DONE | `Makefile`: `get`, `build_runner_build`, `build_runner_watch`, `test`, `analyze` |
| env files kept out of git, `.env.example` present | PARTIAL | `.env.example` and `.env.dev` exist; did not verify `.gitignore` entry in this pass — confirm before treating as done |

## 3. Priority 1 items

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | CI with GitHub Actions | DONE for what's scoped; one gap left | `.github/workflows/ci.yml`: on push/PR to `main`, pins Flutter 3.47.5, runs `make get` / `make build_runner_build` / `make format_check` / `make analyze` / `make test`, uploads the coverage report (`coverage/lcov.info`) as a build artifact. CI badge in `README.md`. **Branch protection is on**, requiring the `analyze-and-test` check (set via `gh api` PUT on `branches/main/protection`). No coverage badge/threshold yet (artifact only, no Codecov-style integration — needs an account decision). Still missing: a separate Android/Web build job. The "stale generated files" check from the original plan doesn't apply here: this repo intentionally gitignores `.g.dart`/`.freezed.dart` (see `CLAUDE.md`), so there's no committed baseline to diff against; codegen correctness is covered implicitly since `analyze`/`test` fail if codegen is broken. |
| 2 | Visible, honest test suite | PARTIAL, unchanged | 7 `*_test.dart` files total, covering only `auth` (2 files) and `tasks` (5 files). No golden tests. No `integration_test/` directory. No coverage badge/threshold (coverage IS now collected in CI, see item 1, just not gated or badged). `home/`, `profile/`, `timer/` still untested placeholder screens. **Still the largest open P1 item.** |
| 3 | Lint and quality gates | PARTIAL, Dependabot resolved | `analysis_options.yaml` still strict and good. `riverpod_lint`/`custom_lint` are **still not installed** — worth adding now specifically, since `riverpod_lint 3.1.9` (matching the app's now-current Riverpod 3.x) is available and should install cleanly, where it might have fought the old Riverpod 2.x pin. `.github/dependabot.yml` exists. All 6 Dependabot PRs from the prior pass are resolved: #5 (actions/checkout), #6 (flutter_dotenv), #10 (flutter_svg) merged; #9 (supabase_flutter) fixed (`anonKey` → `publishableKey` deprecation) and merged; #7 (meta) closed, unfixable as long as the Flutter SDK pins `meta` via `flutter_test` — worth a Dependabot ignore rule for `meta` to stop it recurring; #8 (go_router) closed, superseded by PR #13's direct bump to 18.0.1. No pre-commit hook config. |
| 4 | ADRs in `docs/adr/` | **MISSING** | No `docs/adr/` directory. |
| 5 | README as evidence index | PARTIAL | README has a CI badge. Still no screenshots, no demo link, no evidence table, no testing/contributing/decisions sections spelled out (CONTRIBUTING.md exists but isn't linked from the README). |
| 6 | Repo hygiene (CONTRIBUTING, PR template, issue templates, LICENSE, CODEOWNERS) | PARTIAL | `CONTRIBUTING.md`, `LICENSE` (MIT-style, confirm license choice is intentional), `.github/pull_request_template.md`, and `.github/ISSUE_TEMPLATE/bug_report.md` all exist. Still missing: `CODEOWNERS`, a feature-request issue template. |
| 7 | Agent and spec files | PARTIAL | `CLAUDE.md` exists at root (this file — 27KB, detailed). `AGENTS.md` does **not** exist. No `specs/` directory. Note: `.cursor/rules.md` and 12 `.cursor/skills/*.mdc` files also exist and appear to be the source the current `.claude/skills/` were converted from — worth mentioning in `docs/ai-workflow.md` when written. |

### 3a. Stack currency (not an explicit plan item, but now-completed prerequisite work)

Not part of the original plan's checklist, but came up directly out of P1.3's Dependabot triage and is worth recording since it touches the "keep core stack" hard constraint:

- Flutter SDK bumped 3.41.0 to 3.47.5 (7 months of updates), unblocking the `go_router` major bump.
- `flutter_riverpod`/`riverpod_annotation`/`riverpod_generator` bumped 2.x to 3.x/4.x, `freezed`/`freezed_annotation` bumped 2.x to 4.x/3.x, plus `json_serializable`, `build_runner`, `flutter_lints` — the old pins resolved an `analyzer` version that crashed codegen outright under the newer Dart SDK bundled with 3.47.5.
- Every `@riverpod` provider updated for Riverpod 3's removed generated `Ref` typedefs; every `@freezed` model updated for the new `abstract class` requirement; `authStateProvider` marked `keepAlive: true` (was getting torn down mid-read by controllers); Riverpod 3's default provider auto-retry disabled (`retry: null`) to preserve the app's existing immediate-error-surfacing design.
- iOS/macOS deployment targets bumped to Flutter 3.47.5's minimums (15.0 / 12.0).
- Separately, iOS simulator builds were broken by CocoaPods not being installed on the dev machine — fixed via Homebrew, verified with an actual build + install + launch reaching the login screen.
- Landed as [PR #13](https://github.com/Ali-Assi-1994/telos/pull/13) (merged). CI verified green both locally and on GitHub's runners.

This closes the version-currency risk that made several other gap items harder to reason about (an old, difficult-to-bump SDK pin makes every future dependency bump riskier).

## 4. Priority 2 items

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | Offline-first tasks | **MISSING** | No `drift`/`sqflite`/`isar`/`hive` in `pubspec.yaml`. Net-new work, not a small addition — there is no sync/outbox concept anywhere yet. |
| 2 | Supabase depth (migrations, RLS, RPC, one Edge Function) | **MISSING**, and larger than the plan implies | No `supabase/` directory at all. Zero RLS policies exist as code (only as prose in `docs/database_schema.md`). Zero `.rpc()` calls in `lib/`. This item is really "stand up the backend that the docs describe," not "verify and add RLS tests" as the plan phrases it. |
| 3 | Observability (Sentry) | **MISSING** | No `sentry_flutter` in `pubspec.yaml`. No custom `ProviderObserver` anywhere in `lib/`. Also independently flagged in `docs/todo.md` ("AnalyticsService stub / Sentry wiring"). |
| 4 | Environments and flavors | PARTIAL/MISSING | Only `.env.dev` and `.env.example` exist (no `.env.staging`/`.env.prod`). No Android flavor config found (no `android/app/build.gradle*` located at all in this pass, worth a direct check). Only one iOS scheme (`Runner`), no per-environment schemes. |
| 5 | Responsive UI + live Web demo | Not assessed in this pass | Needs a follow-up check of actual breakpoint usage in `lib/src/common_widgets` and screens; flag for next audit round. |
| 6 | Deep links | **MISSING** | No groups/invite feature exists yet to hang this on (see Section 0 — `groups` feature isn't built). |
| 7 | Notifications | **MISSING** | No `flutter_local_notifications` or `firebase_messaging` in `pubspec.yaml`. |
| 8 | Realtime | **MISSING** | Zero `.channel(`/realtime usage in `lib/`. Also blocked on `groups`/`leaderboard` not existing yet. |
| 9 | Release automation (fastlane) | **MISSING** | No `fastlane/` directory. |
| 10 | Performance pass | **MISSING** | No `docs/performance.md`. |

## 5. Priority 3 (AI-native stretch)

Not started: no LLM Edge Function, no `docs/ai-guardrails.md`, no pgvector/RAG,
no AI-generated e2e specs. One relevant existing risk found during this audit,
outside the plan's own list:

- `create_task_sheet.dart` currently fakes "AI category suggestions" using
  `Random()`, not a real model call. `docs/todo.md` already flags this as
  high risk given the resume's AI-related claims. This is directly relevant
  to Section 6/P3.1 of the plan (the honest Edge-Function-backed LLM
  feature) and to the plan's own principle: "claim on a resume only what is
  built." Recommend fixing this before or alongside any P3 work, since a
  fake AI feature sitting in the repo cuts against the entire evidence
  effort.

## 6. Things already tracked outside this plan (avoid duplicate planning)

Two docs already exist that overlap with this plan and should be reconciled
rather than run in parallel:

- `docs/next_steps_plan.md` — an earlier, partially stale product roadmap
  (predates the auth/tasks work that's since shipped; several "current
  state" rows are now wrong, e.g. it says `flutter_dotenv` is missing, but
  it is present in `pubspec.yaml` today).
- `docs/todo.md` — actively maintained, all "Critical"/"High"/"Medium" items
  already closed per recent commits. Its open "Carried over" section listed
  "Add a CI workflow" and a Sentry/AnalyticsService stub as outstanding;
  the CI item is now done (see Section 3, item 1) and should be checked off
  there. The fake AI random-suggestion issue and the Sentry/AnalyticsService
  item are still open.

## 7. Net effect on the plan's recommended order

Status as of this update: P1.1 (CI) is effectively done. P1.3 (lint/Dependabot)
is down to one small remaining task. Stack currency (Section 3a) is done.
Remaining P1 work:

1. ~~Gap report~~ — done, this document.
2. ~~P1.1 CI hardening~~ — done ([PR #12](https://github.com/Ali-Assi-1994/telos/pull/12)):
   format check, coverage collection, branch protection.
3. ~~Dependabot triage~~ — done: 4 merged, 1 closed (unfixable `meta` conflict,
   add a Dependabot ignore rule), 1 closed (superseded by the direct bump).
4. ~~Stack currency~~ — done ([PR #13](https://github.com/Ali-Assi-1994/telos/pull/13)):
   Flutter 3.47.5, Riverpod 3.x, freezed 4.x, plus the iOS build fix.
5. **Next up — pick one:**
   - **P1.3 remainder**: add `riverpod_lint`/`custom_lint` now, while the
     Riverpod 3.x context is fresh. Small, fast, low-risk.
   - **P1.4**: ADRs in `docs/adr/` — cheap, doc-only, no code dependencies.
   - **P1.2**: the test suite — now the single largest open P1 item (golden
     tests, integration tests, coverage threshold/badge, `home`/`profile`/
     `timer` coverage). Bigger than the other two, highest resume-evidence
     value.
6. P1.5-P1.7 (README evidence table + screenshots + demo link, CODEOWNERS,
   AGENTS.md + `specs/`) — CONTRIBUTING/LICENSE/PR/issue templates are
   already done, so this is narrower than originally scoped.
7. **New, before P2.1**: get the schema out of prose and into
   `supabase/migrations/` under version control, since P2.1 (offline sync),
   P2.2 (RLS tests), and CI's future `supabase start` job all depend on
   migrations existing at all.
8. P2.1 offline-first (tasks feature already exists, so this is buildable
   now), P2.2 Supabase depth, P2.3 observability.
9. P2.6 (deep links) and P2.8 (realtime) need the `groups`/`leaderboard`
   features built first — they don't exist yet. Either build minimal
   versions of those features, or swap in a different evidence hook (e.g.
   realtime evidence via task list updates within `tasks`, which does
   exist).
10. Rest of P2, then P3 only after Ali confirms priorities.
