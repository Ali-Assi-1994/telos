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
import 'package:telos/src/features/tasks/presentation/tasks_providers.dart';
import 'package:telos/src/features/tasks/presentation/tasks_screen.dart';

import '../features/auth/data/fakes/fake_auth_repository.dart';
import '../features/tasks/data/fakes/fake_task_repository.dart';

// TasksHeader renders the real month name and a week strip of actual
// calendar day numbers for whatever selectedDateProvider resolves to. Left
// at its default (DateTime.now()), the golden image would show today's
// date and go stale the next day. Pinning it keeps the golden reproducible.
final DateTime _fixedDate = DateTime(2026, 1, 15);

class _FixedSelectedDate extends SelectedDate {
  @override
  DateTime build() => _fixedDate;
}

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
    taskRepository.seedTask(
      Task(
        id: 't1',
        userId: testUser.id,
        title: 'Write report',
        points: 20,
        assignedDate: _fixedDate,
        createdAt: _fixedDate,
        updatedAt: _fixedDate,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        // Match the app's retry: null (main.dart) so errors surface
        // immediately instead of retrying with real timer delays.
        retry: (int retryCount, Object error) => null,
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(initialUser: testUser),
          ),
          taskRepositoryProvider.overrideWithValue(taskRepository),
          selectedDateProvider.overrideWith(() => _FixedSelectedDate()),
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
