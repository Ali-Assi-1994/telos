import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';
import 'package:telos/src/features/tasks/data/supabase_task_repository.dart';
import 'package:telos/src/features/tasks/domain/task.dart';
import 'package:telos/src/features/tasks/presentation/tasks_screen.dart';

import '../../auth/data/fakes/fake_auth_repository.dart';
import '../data/fakes/fake_task_repository.dart';

void main() {
  const AppUser testUser = AppUser(id: 'user-1', email: 'user@example.com');

  Widget buildApp(FakeTaskRepository taskRepository) {
    return ProviderScope(
      // Match the app's retry: null (main.dart) so errors surface
      // immediately instead of Riverpod 3's default auto-retry.
      retry: (int retryCount, Object error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(initialUser: testUser),
        ),
        taskRepositoryProvider.overrideWithValue(taskRepository),
      ],
      child: const MaterialApp(home: TasksScreen()),
    );
  }

  DateTime todayDateOnly() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  testWidgets('shows a task once loaded and completes it on tap', (
    WidgetTester tester,
  ) async {
    final FakeTaskRepository taskRepository = FakeTaskRepository();
    final DateTime today = todayDateOnly();
    taskRepository.seedTask(
      Task(
        id: 't1',
        userId: testUser.id,
        title: 'Write report',
        points: 20,
        assignedDate: today,
        createdAt: today,
        updatedAt: today,
      ),
    );

    await tester.pumpWidget(buildApp(taskRepository));
    await tester.pumpAndSettle();

    expect(find.text('Write report'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.radio_button_unchecked_rounded));
    await tester.pumpAndSettle();

    expect(taskRepository.tasks.single.completed, isTrue);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('shows an error message when loading tasks fails', (
    WidgetTester tester,
  ) async {
    final FakeTaskRepository taskRepository = FakeTaskRepository()
      ..throwOnGetTasks = true;

    await tester.pumpWidget(buildApp(taskRepository));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load tasks right now. Please try again.'),
      findsOneWidget,
    );
  });
}
