import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:telos/src/features/auth/presentation/auth_state_provider.dart';
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
@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);
  final isAuthenticated = authState.valueOrNull != null;

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final redirectLocation = authGuardRedirect(
        state: state,
        isAuthenticated: isAuthenticated,
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
