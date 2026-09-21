// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
// The ProviderScope below is the root scope for the widget tree under test
// (passed straight to $.pumpWidgetAndSettle), but riverpod_lint only
// recognizes tester.pumpWidget/runApp as root-creating calls, not Patrol's
// own pumpWidgetAndSettle, so it conservatively warns as if this might be a
// nested scope.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:telos/app.dart';
import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/tasks/data/supabase_task_repository.dart';

import '../test/features/auth/data/fakes/fake_auth_repository.dart';
import '../test/features/tasks/data/fakes/fake_task_repository.dart';

void main() {
  patrolTest('signing in with valid credentials reaches the home screen', (
    PatrolIntegrationTester $,
  ) async {
    final FakeAuthRepository authRepository = FakeAuthRepository();

    await $.pumpWidgetAndSettle(
      ProviderScope(
        // Match the app's retry: null (main.dart) so errors surface
        // immediately instead of Riverpod 3's default auto-retry.
        retry: (int retryCount, Object error) => null,
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          taskRepositoryProvider.overrideWithValue(FakeTaskRepository()),
        ],
        child: const App(),
      ),
    );

    // Signed out: the auth guard redirects from splash straight to login.
    expect($(find.text('Welcome back')), findsOneWidget);

    await $.enterText(find.byType(TextFormField).first, 'user@example.com');
    await $.enterText(find.byType(TextFormField).at(1), 'password123');
    await $.tap(find.text('Log In'));
    await $.pumpAndSettle();

    expect(authRepository.currentUser, isNotNull);
    expect($(find.text("You're in. Tasks will go here.")), findsOneWidget);
  });
}
