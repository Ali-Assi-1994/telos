import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:telos/src/features/auth/data/auth_repository.dart';
import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';
import 'package:telos/src/features/auth/presentation/login_screen.dart';
import 'package:telos/src/features/auth/presentation/register_screen.dart';
import 'package:telos/src/features/home/presentation/home_screen.dart';
import 'package:telos/src/features/navigation/presentation/main_bottom_nav_bar.dart';
import 'package:telos/src/features/profile/presentation/profile_screen.dart';
import 'package:telos/src/features/tasks/presentation/tasks_screen.dart';
import 'package:telos/src/features/timer/presentation/timer_screen.dart';
import 'package:telos/src/utils/logger.dart';
import 'package:telos/src/routing/app_routes.dart';
import 'package:telos/src/routing/auth_guard.dart';

part 'app_router.g.dart';

/// Top-level router configuration for the app.
///
/// Built exactly once: only [authRepositoryProvider] (a stable singleton) is
/// watched, so this provider's body never re-runs. Auth-driven redirects are
/// instead handled by [_AuthRefreshListenable], which notifies GoRouter to
/// re-evaluate `redirect` without tearing down and rebuilding the whole
/// [GoRouter] instance (and its navigation stack) on every sign-in/sign-out.
@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authListenable = _AuthRefreshListenable(authRepository);
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final redirectLocation = authGuardRedirect(
        state: state,
        isAuthenticated: authListenable.isAuthenticated,
      );
      if (redirectLocation != null) {
        AppLogger.routing.info('Redirecting to $redirectLocation');
      }
      return redirectLocation;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainTabsShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.tasks,
                name: 'tasks',
                builder: (context, state) => const TasksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.timer,
                name: 'timer',
                builder: (context, state) => const TimerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _MainTabsShell extends StatelessWidget {
  const _MainTabsShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onSelected: (int index) {
          navigationShell.goBranch(index);
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Bridges [AuthRepository.authStateChanges] to a [Listenable] GoRouter can
/// use as `refreshListenable`, so only `redirect` re-runs on auth changes
/// instead of the entire [GoRouter] instance being rebuilt.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(AuthRepository authRepository)
      : isAuthenticated = authRepository.currentUser != null {
    _subscription = authRepository.authStateChanges.listen((AppUser? user) {
      isAuthenticated = user != null;
      notifyListeners();
    });
  }

  bool isAuthenticated;
  late final StreamSubscription<AppUser?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
