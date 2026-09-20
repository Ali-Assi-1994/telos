// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
// The ProviderScope below is the root scope for the widget tree under test
// (passed straight to tester.pumpWidget), but riverpod_lint can't trace that
// through this indirection and conservatively warns as if it might be a
// nested scope.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/app.dart';
import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';
import 'package:telos/src/features/tasks/data/supabase_task_repository.dart';
import 'package:telos/src/features/tasks/domain/task.dart';
import 'package:telos/src/features/tasks/presentation/tasks_screen.dart';

import '../features/auth/data/fakes/fake_auth_repository.dart';
import '../features/tasks/data/fakes/fake_task_repository.dart';

void main() {
  testWidgets('TasksScreen matches golden with a task loaded', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const AppUser testUser = AppUser(id: 'user-1', email: 'user@example.com');
    final FakeTaskRepository taskRepository = FakeTaskRepository();
    final DateTime today = DateTime.now();
    final DateTime dateOnly = DateTime(today.year, today.month, today.day);
    taskRepository.seedTask(
      Task(
        id: 't1',
        userId: testUser.id,
        title: 'Write report',
        points: 20,
        assignedDate: dateOnly,
        createdAt: dateOnly,
        updatedAt: dateOnly,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(initialUser: testUser),
          ),
          taskRepositoryProvider.overrideWithValue(taskRepository),
        ],
        child: MaterialApp(theme: appTheme, home: const TasksScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TasksScreen),
      matchesGoldenFile('goldens/tasks_screen.png'),
    );
  });
}
