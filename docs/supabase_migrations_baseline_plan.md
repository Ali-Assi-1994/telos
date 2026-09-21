# Supabase Migrations Baseline — Implementation Plan

Get the live Supabase schema under version control in this repo. Written so
implementation can start cold in a new session.

**Why this matters now, specifically**: `docs/EVIDENCE_GAP_REPORT.md`
(gitignored, local-only — read it first if present) has flagged "no
`supabase/` directory in git" as the single biggest structural gap for a
while. It got concretely worse with the `performance` feature
([PR #22](https://github.com/Ali-Assi-1994/telos/pull/22)): two RPCs
(`get_daily_performance`, `get_streak`) now back shipped, tested features,
and neither has a line of SQL anywhere in this repo. If the live project
changed or got deleted, there is currently no way to reproduce it from git.

---

## Verified facts (don't re-derive these, they're already confirmed)

- Live project ref: `gwvseuxuafjkygqcxeae`. Referenced in `.mcp.json` (a
  `supabase` MCP server is already configured for it) and in `.env.dev`
  (gitignored, `SUPABASE_URL=https://gwvseuxuafjkygqcxeae.supabase.co`).
- **This is a live hosted Supabase Cloud project, not a local Docker
  instance**, despite `CLAUDE.md`'s Environment Configuration section
  commenting `.env.dev # local Supabase instance`. That comment is wrong in
  practice; worth a one-line fix while in the area, not the main goal.
- No `supabase/` directory anywhere in this repo's git history.
- What the app actually calls today (grep `lib/` for `.from(`/`.rpc(` if you
  want to re-verify): tables `categories`, `tasks`, `task_categories`
  (`profiles` only implicitly, via the `handle_new_user` auth trigger —
  no direct `.from('profiles')` call); RPCs `complete_task`,
  `uncomplete_task`, `get_daily_performance`, `get_streak`.
- `docs/database_schema.md` documents a much larger schema (9 tables
  including `task_templates`, `groups`, `group_members`, `app_settings`;
  6 RPCs including `get_leaderboard`, `lock_expired_tasks`,
  `generate_template_instances`). **Whether any of that beyond what's
  listed above actually exists on the live project is unverified.** Treat
  the doc as aspirational/target, not as ground truth for what's deployed.
- The `performance` feature work found a real migration already applied on
  the live project: `20260317184250_init_productivity_app_schema`,
  containing `get_streak` byte-identical to the MVP spec in
  `docs/database_schema.md` §6. That's strong evidence the schema actually
  was originally authored through Supabase's own migration system, just
  never pulled into this repo.

## The key lead: migration history is likely fully recoverable

Supabase's own `supabase_migrations.schema_migrations` table stores, per
applied migration, a `version`, `name`, and a `statements` column
containing the **raw SQL that was actually run**. The performance-feature
session already queried this table successfully (via the `execute_sql` MCP
tool) to find `get_streak`. That means the full migration history is very
likely recoverable by querying it directly:

```sql
SELECT version, name, statements
FROM supabase_migrations.schema_migrations
ORDER BY version;
```

If this returns real rows, **this is the fast, accurate path** — write each
row out to `supabase/migrations/<version>_<name>.sql` (Supabase CLI's exact
naming convention: `<timestamp>_<name>.sql`), and the schema is baselined
with the actual SQL that built it, not a best-effort re-derivation.

Only fall back to `supabase db pull` (needs the CLI, `supabase login`,
`supabase link --project-ref gwvseuxuafjkygqcxeae`) if that table is empty
or inaccessible — it produces a single consolidated schema dump instead of
real history, which is a reasonable fallback but strictly worse than the
above.

---

## Steps

### Step 1 — Confirm MCP access

- [x] Try `mcp__supabase__list_migrations` first (cheap, read-only). It was
      `Unauthorized` in one session this project (no `SUPABASE_ACCESS_TOKEN`
      in that shell) but worked in another (the performance-feature session
      used `execute_sql`/`list_migrations` successfully) — so it may just
      work already. If unauthorized, the token needs to be set as an env var
      in the shell this session's MCP servers launch from, then the session
      restarted. Don't ask the user to paste the token into chat.
      **Confirmed working** — returned `20260317184250_init_productivity_app_schema`
      with no auth error. CLI fallback not needed.
- [ ] If MCP genuinely can't be authenticated and CLI installation is
      preferred instead: `brew install supabase/tap/supabase`,
      `supabase login` (browser OAuth), `supabase link --project-ref gwvseuxuafjkygqcxeae`.

### Step 2 — Recover migration history

- [x] Run the `schema_migrations` query above via `execute_sql`.
      One row came back: `20260317184250_init_productivity_app_schema`.
- [x] For each row, write `supabase/migrations/<version>_<name>.sql` with
      that row's `statements` content.
      Written to [supabase/migrations/20260317184250_init_productivity_app_schema.sql](../supabase/migrations/20260317184250_init_productivity_app_schema.sql).
      Content verified byte-accurate against the live DB via an MD5 hash of
      the whitespace-normalized text, computed both server-side and locally.
- [ ] If using the CLI as a fallback instead: `supabase db pull` generates
      `supabase/migrations/<timestamp>_remote_schema.sql` in one file. Less
      ideal (loses history granularity) but acceptable if Step 2's query
      comes back empty.

### Step 3 — Reconcile against the docs

- [x] Diff the recovered schema against `docs/database_schema.md`. Expect
      `profiles`, `categories`, `tasks`, `task_categories`, `get_daily_performance`,
      `get_streak`, `complete_task`, `uncomplete_task` to match. Note (don't
      "fix") any drift for `task_templates`, `groups`, `group_members`,
      `app_settings`, `get_leaderboard`, `lock_expired_tasks`,
      `generate_template_instances` — whatever their actual state turns out
      to be, leave it as-is; those have no app consumer yet (see Out of
      Scope).

      **Result**: all 9 tables, all indexes, all triggers, all RLS
      policies, and 6 of 7 documented RPCs (`complete_task`,
      `uncomplete_task`, `get_daily_performance`, `get_streak`,
      `get_leaderboard`, `lock_expired_tasks`) match the doc exactly —
      confirmed live via `list_tables` and a `pg_proc` query.

      One real divergence, confirmed via `list_migrations`/`pg_proc`/
      `cron.job_run_details`: `generate_template_instances` is fully
      documented in §6 and scheduled in §7's cron job, but was **never
      actually created** on the live project — it's absent from both the
      recovered migration and `pg_proc`. The `generate-recurring-instances`
      cron job has been failing every night since at least 2026-09-17 with
      `function generate_template_instances(uuid, date, date) does not
      exist`. No app consumer uses `task_templates` yet, so this is inert —
      left as-is per scope, noted in `docs/database_schema.md` §6/§7.

      Also found (untracked, harmless): a `public.update_updated_at_column`
      function exists live but isn't referenced by any trigger and isn't in
      the migration or docs — dead code from an earlier iteration, not
      touched.
- [x] Update `docs/database_schema.md` to point at `supabase/migrations/` as
      the source of truth rather than standalone prose, or at least note
      where they diverge.

### Step 4 — RLS sanity check

- [ ] `mcp__supabase__get_advisors(type: "security")` — one call, tells you
      whether RLS is actually enabled on the tables in use or if that
      section of `docs/database_schema.md` was ever really applied.
- [ ] File anything it flags as a follow-up; fixing it is optional for this
      plan's scope, but don't skip running the check.

### Step 5 — Wrap up

- [ ] Commit `supabase/migrations/`.
- [ ] Fix `CLAUDE.md`'s `.env.dev # local Supabase instance` comment to
      reflect reality (hosted project, not local Docker) — small, honest,
      while in the area.
- [ ] Update `docs/EVIDENCE_GAP_REPORT.md` if present (gitignored, local
      only) to close out the "no `supabase/` directory" item.
- [ ] Delete this plan file once done, or fold anything still relevant into
      `docs/todo.md` — matches how `docs/performance_feature_plan.md` was
      closed out.
- [ ] Open a PR. No Claude attribution footer in the PR body, no
      meta-commentary about session planning in the description (repo
      convention, see prior PRs).

---

## Explicitly out of scope

- Building `groups`/`leaderboard`/`task_templates` tables or features —
  no app code uses them; this plan only baselines what's real.
- Deploying any new RPC or table. This is a capture-what-exists task, not a
  schema-design task.
- pgTAP RLS test coverage — good follow-up once migrations exist, but a
  separate, larger piece of work (needs a local Docker Postgres stack via
  `supabase start`). Don't pull it into this plan's scope unless it turns
  out to be trivial once the migrations are in place.
- Timezone-aware anything (explicitly deferred, see `docs/architecture.md`
  Decision 7).
