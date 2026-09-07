import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/tasks/data/supabase_task_repository.dart';
import 'package:telos/src/features/tasks/domain/task.dart';
import 'package:telos/src/features/tasks/presentation/task_mutation_controller.dart';

import '../../auth/data/fakes/fake_auth_repository.dart';
import '../data/fakes/fake_task_repository.dart';

void main() {
  late FakeTaskRepository taskRepository;
  late FakeAuthRepository authRepository;
  late ProviderContainer container;

  final User testUser = User(
    id: 'user-1',
    appMetadata: const <String, dynamic>{},
    userMetadata: const <String, dynamic>{},
    aud: 'authenticated',
    createdAt: DateTime(2026).toIso8601String(),
  );

  Task buildTask({bool completed = false, bool isLocked = false}) {
    final DateTime date = DateTime(2026, 1, 15);
    return Task(
      id: 't1',
      userId: testUser.id,
      title: 'Write report',
      points: 20,
      assignedDate: date,
      completed: completed,
      isLocked: isLocked,
      createdAt: date,
      updatedAt: date,
    );
  }

  setUp(() {
    taskRepository = FakeTaskRepository();
    authRepository = FakeAuthRepository(
      initialSession: Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: testUser,
      ),
    );
    container = ProviderContainer(
      overrides: <Override>[
        taskRepositoryProvider.overrideWithValue(taskRepository),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('toggling an incomplete task marks it complete', () async {
    final Task task = buildTask();
    taskRepository.seedTask(task);

    await container
        .read(taskMutationControllerProvider.notifier)
        .toggleCompleted(task);

    expect(container.read(taskMutationControllerProvider).hasError, isFalse);
    expect(taskRepository.tasks.single.completed, isTrue);
    expect(taskRepository.completeCallCount, 1);
    expect(taskRepository.uncompleteCallCount, 0);
  });

  test('toggling a completed task marks it incomplete', () async {
    final Task task = buildTask(completed: true);
    taskRepository.seedTask(task);

    await container
        .read(taskMutationControllerProvider.notifier)
        .toggleCompleted(task);

    expect(taskRepository.tasks.single.completed, isFalse);
    expect(taskRepository.uncompleteCallCount, 1);
    expect(taskRepository.completeCallCount, 0);
  });

  test('locked tasks are a no-op and never reach the repository', () async {
    final Task task = buildTask(isLocked: true);
    taskRepository.seedTask(task);

    await container
        .read(taskMutationControllerProvider.notifier)
        .toggleCompleted(task);

    expect(taskRepository.completeCallCount, 0);
    expect(taskRepository.uncompleteCallCount, 0);
    expect(taskRepository.tasks.single.completed, isFalse);
  });

  test('repository failure surfaces as an AppException in state', () async {
    final Task task = buildTask();
    taskRepository.seedTask(task);
    taskRepository.throwOnComplete = true;

    await container
        .read(taskMutationControllerProvider.notifier)
        .toggleCompleted(task);

    final AsyncValue<void> state = container.read(taskMutationControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<DatabaseAppException>());
  });
}
