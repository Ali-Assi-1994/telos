import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/presentation/login_screen.dart';

import '../data/fakes/fake_auth_repository.dart';

Future<void> _pumpLoginScreen(
  WidgetTester tester,
  FakeAuthRepository authRepository,
) async {
  // The login form is taller than the default 800x600 test surface, which
  // would leave the submit button off-screen. Use a taller surface instead
  // of scrolling so widget lookups stay simple.
  tester.view.physicalSize = const Size(480, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      // Match the app's retry: null (main.dart) so errors surface
      // immediately instead of Riverpod 3's default auto-retry.
      retry: (int retryCount, Object error) => null,
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
}

void main() {
  testWidgets('shows validation errors when submitting an empty form', (
    WidgetTester tester,
  ) async {
    await _pumpLoginScreen(tester, FakeAuthRepository());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    // The password field's hint text and its validator message are the same
    // string ("Enter your password"), so assert on form-field validity
    // rather than matching text.
    final FormFieldState<String> emailField = tester
        .state<FormFieldState<String>>(find.byType(TextFormField).at(0));
    final FormFieldState<String> passwordField = tester
        .state<FormFieldState<String>>(find.byType(TextFormField).at(1));
    expect(emailField.hasError, isTrue);
    expect(passwordField.hasError, isTrue);
  });

  testWidgets('valid credentials sign in without showing an error', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository authRepository = FakeAuthRepository();
    await _pumpLoginScreen(tester, authRepository);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(authRepository.currentUser, isNotNull);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('failed sign-in shows the friendly error message in a snackbar', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository authRepository = FakeAuthRepository()
      ..failNextAuth = true
      ..failureMessage = 'Invalid email or password. Please try again.';
    await _pumpLoginScreen(tester, authRepository);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(
      find.text('Invalid email or password. Please try again.'),
      findsOneWidget,
    );
  });
}
