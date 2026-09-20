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
import 'package:telos/src/features/auth/domain/app_user.dart';
import 'package:telos/src/features/tasks/data/supabase_task_repository.dart';
import 'package:telos/src/features/tasks/domain/task.dart';

import '../test/features/auth/data/fakes/fake_auth_repository.dart';
import '../test/features/tasks/data/fakes/fake_task_repository.dart';

const AppUser _testUser = AppUser(id: 'user-1', email: 'user@example.com');

Future<void> _pumpSignedInApp(
  PatrolIntegrationTester $,
  FakeTaskRepository taskRepository,
) async {
  await $.pumpWidgetAndSettle(
    ProviderScope(
      // Match the app's retry: null (main.dart) so errors surface
      // immediately instead of Riverpod 3's default auto-retry.
      retry: (int retryCount, Object error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(initialUser: _testUser),
        ),
        taskRepositoryProvider.overrideWithValue(taskRepository),
      ],
      child: const App(),
    ),
  );

  // Already signed in: lands on home. Switch to the tasks tab.
  await $.tap(find.byIcon(Icons.inbox_outlined));
  await $.pumpAndSettle();
}

void main() {
  patrolTest('creates a task and shows it in the tasks list', (
    PatrolIntegrationTester $,
  ) async {
    final FakeTaskRepository taskRepository = FakeTaskRepository();
    await _pumpSignedInApp($, taskRepository);

    // Opens the create-task sheet from the first free-time slot.
    await $.tap(find.byIcon(Icons.add_rounded).first);
    await $.pumpAndSettle();

    await $.enterText(find.byType(TextFormField), 'Write report');
    await $.tap(find.text('Save Task'));
    await $.pumpAndSettle();

    expect($(find.text('Write report')), findsOneWidget);
    expect(taskRepository.tasks.single.title, 'Write report');
  });

  patrolTest('completes a task from the tasks list', (
    PatrolIntegrationTester $,
  ) async {
    final FakeTaskRepository taskRepository = FakeTaskRepository();
    final DateTime today = DateTime.now();
    final DateTime dateOnly = DateTime(today.year, today.month, today.day);
    taskRepository.seedTask(
      Task(
        id: 't1',
        userId: _testUser.id,
        title: 'Write report',
        points: 20,
        assignedDate: dateOnly,
        createdAt: dateOnly,
        updatedAt: dateOnly,
      ),
    );
    await _pumpSignedInApp($, taskRepository);

    expect($(find.text('Write report')), findsOneWidget);

    await $.tap(find.byIcon(Icons.radio_button_unchecked_rounded));
    await $.pumpAndSettle();

    expect(taskRepository.tasks.single.completed, isTrue);
    expect($(find.byIcon(Icons.check_circle_rounded)), findsOneWidget);
  });
}
