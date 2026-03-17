import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/logger.dart';
import 'app_routes.dart';
import 'auth_guard.dart';

part 'app_router.g.dart';

/// Top-level router configuration for the app.
@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  // TODO: Replace this placeholder with a real auth state provider once
  // the auth feature is implemented.
  const bool isAuthenticated = false;

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
      // Additional feature routes will be added here.
    ],
  );
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

