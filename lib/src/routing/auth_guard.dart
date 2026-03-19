import 'package:go_router/go_router.dart';

import 'package:telos/src/utils/logger.dart';

/// Encapsulates authentication-based redirect logic for the router.
///
/// At this stage, the guard is a placeholder that can be wired up to an
/// auth state provider once the auth feature is implemented.
String? authGuardRedirect({
  required GoRouterState state,
  required bool isAuthenticated,
}) {
  AppLogger.routing.info(
    'Evaluating auth redirect',
    error: {
      'location': state.uri.toString(),
      'isAuthenticated': isAuthenticated,
    },
  );

  final isOnAuthPath = state.matchedLocation.startsWith('/auth');
  final isOnSplash = state.matchedLocation == '/';

  if (!isAuthenticated && !isOnAuthPath) {
    return '/auth/login';
  }

  if (isAuthenticated && (isOnAuthPath || isOnSplash)) {
    return '/home';
  }

  return null;
}
