import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/app.dart';
import 'package:telos/src/features/tasks/presentation/widgets/task_list_states.dart';

void main() {
  testWidgets('TaskListLoadingSkeleton matches golden', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(480, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: TaskListLoadingSkeleton()),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/task_list_loading_skeleton.png'),
    );
  });

  testWidgets('TaskListErrorState matches golden', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(480, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(
          body: TaskListErrorState(
            message: 'Could not load tasks right now. Please try again.',
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/task_list_error_state.png'),
    );
  });
}
