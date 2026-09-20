# 0001. Feature-first architecture

## Context

The app is organized around several functional areas (auth, tasks, and
eventually performance, groups, leaderboard). We needed a folder structure
that scales as those areas grow, without turning into either a single flat
`lib/` directory or a maze of one-off folders per screen.

## Decision

Organize `lib/src/features/` by feature: what the user does, not what they
see. Each feature gets up to four layers: `data -> domain -> application
(optional) -> presentation`, following Andrea Bizzotto's feature-first
Riverpod reference architecture. `application/` is added only when a
controller would otherwise need to coordinate two or more repositories.

A feature is a functional area (`tasks`, `auth`), never a single screen
(`login_page`, `task_list_page`); those live inside a feature's
`presentation/` folder instead.

## Alternatives considered

- **Layer-first** (`lib/screens/`, `lib/repositories/`, `lib/models/` at the
  top level): scales poorly past a handful of features, since everything
  related to one feature ends up scattered across unrelated top-level
  folders.
- **Screen-first** (one folder per screen): conflates "what the user does"
  with "what they see." A single feature routinely spans multiple screens
  (`auth` has both `LoginScreen` and `RegisterScreen`), and a screen doesn't
  map cleanly to a bounded business concern.

## Consequences

- New features get a consistent, scaffoldable shape (see the
  `flutter-feature-generator` skill).
- Small/placeholder features (`home`, `profile`, `timer`) still get the full
  folder shape even before they have real `data`/`domain` layers, adding a
  little ceremony for genuinely trivial screens, accepted since they're
  expected to grow into real features.
- Cross-feature dependencies must go through `domain/` only (see
  `docs/architecture.md`, Section 8). An unusually high number of imports
  from another feature's `data/` or `presentation/` layer is the signal that
  something needs to move into a shared area instead, checked by the
  `architecture-check` skill.
