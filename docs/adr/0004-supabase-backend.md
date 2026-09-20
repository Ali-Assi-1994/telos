# 0004. Supabase as the backend

## Context

The app needs authentication, a relational database, and eventually
realtime updates and server-held-secret logic (e.g. an LLM API call),
without taking on the operational cost of hosting and maintaining custom
backend infrastructure for a project at this scale.

## Decision

Supabase (hosted Postgres, Auth, Realtime, and Edge Functions) as the sole
backend, accessed through `supabase_flutter`.

## Alternatives considered

- **Firebase** (Firestore + Cloud Functions + Realtime Database): rejected
  specifically because this project also exists to demonstrate real
  PostgreSQL/SQL experience: migrations, row-level security, relational
  schema design, as a personal-project counterpart to the Node/TypeScript
  Firebase Cloud Functions experience gained on the job. Firestore's
  document model wouldn't back that claim; Supabase's Postgres does.
- **Self-hosted Postgres plus a hand-rolled API** (Node/Dart/etc.): far more
  operational surface (hosting, auth implementation, migration tooling) for
  no real benefit at this scale. Supabase bundles Postgres, Auth, RLS,
  Realtime, and Edge Functions as one hosted product.

## Consequences

- Business rules that need atomicity or can't be trusted to the client
  (task completion, locking, scoring) belong in Postgres functions called
  via `.rpc()`, never reimplemented in Dart (see `docs/architecture.md`,
  Key Architectural Decision 1).
- Supabase Edge Functions (Deno/TypeScript) are the project's analog for
  anything needing a server-held secret (e.g. an LLM API key), described
  and named as Supabase Edge Functions, not Firebase Cloud Functions, in
  any docs or resume material.
- The schema currently exists only as prose in `docs/database_schema.md`,
  not as versioned migrations under `supabase/`. That's a tracked gap (see
  `docs/EVIDENCE_GAP_REPORT.md`), not something this ADR resolves; RLS
  policies, migrations, and RPC functions still need to be written and
  committed.
