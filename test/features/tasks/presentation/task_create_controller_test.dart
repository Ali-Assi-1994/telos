import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';
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
      overrides: <Override>[
        taskRepositoryProvider.overrideWithValue(taskRepository),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('creates a task and records its start-time override', () async {
    const TimeOfDay startTime = TimeOfDay(hour: 9, minute: 30);

    await container.read(taskCreateControllerProvider.notifier).create(
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

    final Map<String, int> overrides =
        container.read(taskStartTimeOverridesProvider);
    expect(overrides[createdTask.id], (9 * 60) + 30);
  });

  test('repository validation failure surfaces as an AppException', () async {
    await container.read(taskCreateControllerProvider.notifier).create(
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
