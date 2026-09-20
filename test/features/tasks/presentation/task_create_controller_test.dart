import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';
import 'package:telos/src/features/auth/presentation/auth_state_provider.dart';
import 'package:telos/src/features/tasks/data/supabase_task_repository.dart';
import 'package:telos/src/features/tasks/presentation/task_create_controller.dart';
import 'package:telos/src/features/tasks/presentation/tasks_providers.dart';

import '../../auth/data/fakes/fake_auth_repository.dart';
import '../data/fakes/fake_task_repository.dart';

void main() {
  late FakeTaskRepository taskRepository;
  late FakeAuthRepository authRepository;
  late ProviderContainer container;

  const AppUser testUser = AppUser(id: 'user-1', email: 'user@example.com');

  setUp(() {
    taskRepository = FakeTaskRepository();
    authRepository = FakeAuthRepository(initialUser: testUser);
    container = ProviderContainer(
      // Match the app's retry: null (main.dart) so errors surface
      // immediately instead of Riverpod 3's default auto-retry.
      retry: (int retryCount, Object error) => null,
      overrides: [
        taskRepositoryProvider.overrideWithValue(taskRepository),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
    addTearDown(container.dispose);
    // Keep the autoDispose controller alive across awaits, the way a widget's
    // ref.listen would in the real app.
    container.listen(taskCreateControllerProvider, (_, _) {});
    // In the real app, tasksForSelectedDate/dailyPerformanceForSelectedDate
    // already ref.watch(authStateProvider) whenever TasksScreen is showing,
    // which is what lets ref.read(authStateProvider.future) resolve inside
    // this controller. Replicate that here, since a bare .read(...future)
    // with no other listener never resolves.
    container.listen(authStateProvider, (_, _) {});
  });

  test('creates a task and records its start-time override', () async {
    const TimeOfDay startTime = TimeOfDay(hour: 9, minute: 30);

    await container
        .read(taskCreateControllerProvider.notifier)
        .create(
          title: 'Plan sprint',
          description: null,
          points: 30,
          assignedDate: DateTime(2026, 1, 15),
          startTime: startTime,
          categoryIds: const <int>[1],
        );

    final AsyncValue<void> state = container.read(taskCreateControllerProvider);
    expect(state.hasError, isFalse);
    expect(taskRepository.tasks, hasLength(1));

    final createdTask = taskRepository.tasks.single;
    expect(createdTask.title, 'Plan sprint');
    expect(createdTask.points, 30);

    final Map<String, int> overrides = container.read(
      taskStartTimeOverridesProvider,
    );
    expect(overrides[createdTask.id], (9 * 60) + 30);
  });

  test('repository validation failure surfaces as an AppException', () async {
    await container
        .read(taskCreateControllerProvider.notifier)
        .create(
          title: '',
          description: null,
          points: 30,
          assignedDate: DateTime(2026, 1, 15),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          categoryIds: const <int>[1],
        );

    final AsyncValue<void> state = container.read(taskCreateControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<DatabaseAppException>());
    expect(taskRepository.tasks, isEmpty);
  });
}
