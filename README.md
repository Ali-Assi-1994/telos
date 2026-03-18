# Telos

Productivity & accountability app built with **Flutter**, **Riverpod**, **GoRouter**, and **Supabase**.

## Stack

- **Flutter**: mobile + web (desktop supported via platform folders)
- **State**: `flutter_riverpod` + `riverpod_annotation` (codegen)
- **Navigation**: `go_router`
- **Backend**: `supabase_flutter`
- **Models**: `freezed` + `json_serializable`

## Architecture

This repo follows a feature-first architecture (Bizzotto-style):

- **Feature layers**: `data → domain → application (optional) → presentation`
- **Shared infrastructure**: `lib/src/{routing,services,utils,exceptions,...}`

See `docs/architecture.md` for the full design and dependency rules.

## Requirements

- Flutter SDK installed and on PATH
- A Supabase project (or local Supabase) with URL + anon key

## Environment setup

We use `.env*` files (ignored by git) for secrets.

- Copy the example:

```bash
cp .env.example .env.dev
```

- Fill in:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`

## Common commands

- Install dependencies:

```bash
flutter pub get
```

- Generate Riverpod/Freezed code:

```bash
make build_runner_build
```

- Watch codegen during development:

```bash
make build_runner_watch
```

- Run analysis / tests:

```bash
make analyze
make test
```

## Project structure (high level)

```
lib/
├── main.dart
├── app.dart
└── src/
    ├── exceptions/
    ├── routing/
    ├── services/
    ├── utils/
    └── features/
```

## Notes

- Don’t commit `.env*` files or IDE files under `.idea/`.
- Don’t edit generated files (`*.g.dart`, `*.freezed.dart`) manually.
