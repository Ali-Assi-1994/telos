# Contributing to Telos

## Before you start

- For anything non-trivial, open an issue first describing what's broken or
  what you want to add, before writing a PR. Small, obvious fixes (typos, a
  broken link) don't need one.
- `main` is protected: every change goes through a pull request, and the
  `analyze-and-test` CI check must pass before it can merge. No exceptions,
  including for the repo owner.

## Branches

Branch off `main`, name it after what it does, prefixed by type:

- `feat/...` -- a new feature
- `fix/...` -- a bug fix
- `chore/...` -- tooling, CI, docs, dependency housekeeping
- `ci/...` -- changes to `.github/workflows`

e.g. `fix/auto-create-env-dev`, `ci/add-github-actions-workflow`.

## Commits

- Explain *why*, not just what -- the diff already shows what changed. A
  one-line summary is fine for small changes; anything with a non-obvious
  reason (a workaround, a root-cause fix, a version pin) should say why in
  the body.
- Keep commits atomic: one logical change per commit. Don't fold an unrelated
  cleanup into a feature commit.

## Before opening a PR

```bash
make get               # installs deps, creates .env.dev from .env.example if missing
make build_runner_build
make analyze
make test
```

All four should pass locally before you push -- CI runs the same four checks
and will block the merge otherwise.

## Code changes

This project follows a feature-first, layered architecture (`data ->
domain -> application (optional) -> presentation`). See `docs/architecture.md`
and the root `CLAUDE.md` for the full rules before touching `lib/`.

## Pull requests

The PR template is applied automatically. Link any issue the PR resolves
(`Closes #N`) so GitHub cross-references it and closes it on merge.
