import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/app.dart';
import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/presentation/login_screen.dart';

import '../features/auth/data/fakes/fake_auth_repository.dart';

void main() {
  testWidgets('LoginScreen matches golden', (WidgetTester tester) async {
    // The login form is taller than the default 800x600 test surface, which
    // would leave the submit button off-screen.
    tester.view.physicalSize = const Size(480, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(theme: appTheme, home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen.png'),
    );
  });
}
