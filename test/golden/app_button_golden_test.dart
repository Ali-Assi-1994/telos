import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/app.dart';
import 'package:telos/src/common_widgets/app_button.dart';

void main() {
  testWidgets('AppPrimaryButton and AppOutlineButton match golden', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppPrimaryButton(label: 'Log In', onPressed: () {}),
                const SizedBox(height: 12),
                AppPrimaryButton(
                  label: 'Log In',
                  isLoading: true,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                AppOutlineButton(
                  onPressed: () {},
                  child: const Text('Continue with Apple'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // A single pump, not pumpAndSettle: AppPrimaryButton's loading state
    // renders an indeterminate CircularProgressIndicator, which animates
    // forever and would make pumpAndSettle time out.
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/app_button.png'),
    );
  });
}
