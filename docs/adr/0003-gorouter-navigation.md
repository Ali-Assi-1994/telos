# 0003. GoRouter for navigation

## Context

The app has an unauthenticated flow (login/register) and an authenticated
tabbed shell (home/tasks/timer/profile), with auth-state-driven redirects
between them, and a general goal of URL-addressable, deep-linkable routes
(needed later for things like group-invite links).

## Decision

`go_router`, using `StatefulShellRoute.indexedStack` for the tab shell and a
`redirect` callback driven by a `Listenable` for auth-state redirects.

## Alternatives considered

- **Imperative `Navigator.push`**: no declarative deep-link support, and
  auth guarding would need to be manually re-checked at every push site
  instead of centrally. `CLAUDE.md` explicitly bans it for main app flows.
- **Hand-rolled Navigator 2.0** (custom `RouterDelegate`/
  `RouteInformationParser`): would reimplement what `go_router`'s
  `StatefulShellRoute` already provides (per-tab navigation stack
  preservation) for no benefit.

## Consequences

- Auth redirect logic is centralized in `auth_guard.dart`, not scattered
  across individual screens.
- The router needed a `Listenable` bridge (`_AuthRefreshListenable` in
  `app_router.dart`) so auth-state changes only re-run `redirect`, instead
  of rebuilding the entire `GoRouter` instance (and losing the navigation
  stack) on every sign-in/sign-out. This was a real bug caught in an earlier
  architecture-audit pass (see `docs/todo.md`); the pattern to follow for
  any future router provider changes.
- Route path constants live in `app_routes.dart`, separate from the router
  config itself, per `CLAUDE.md`'s routing rules.
