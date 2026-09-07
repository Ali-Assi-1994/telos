import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/tasks/data/supabase_task_repository.dart';
import 'package:telos/src/features/tasks/domain/task_create_input.dart';

/// These tests exercise [SupabaseTaskRepository.createTask]'s client-side
/// validation, which runs before any network call. They rely on the client
/// never being reached, so a client pointed at a placeholder URL is safe.
void main() {
  late SupabaseTaskRepository repository;

  setUp(() {
    repository = SupabaseTaskRepository(
      SupabaseClient('https://example.supabase.co', 'anon-key'),
    );
  });

  TaskCreateInput validInput({
    String title = 'Write report',
    int points = 20,
    List<int> categoryIds = const <int>[1],
  }) {
    return TaskCreateInput(
      userId: 'user-1',
      title: title,
      points: points,
      assignedDate: DateTime(2026, 1, 15),
      categoryIds: categoryIds,
    );
  }

  test('rejects a blank title before touching the network', () async {
    await expectLater(
      repository.createTask(validInput(title: '   ')),
      throwsA(isA<DatabaseAppException>()),
    );
  });

  test('rejects points below the 1-100 range', () async {
    await expectLater(
      repository.createTask(validInput(points: 0)),
      throwsA(isA<DatabaseAppException>()),
    );
  });

  test('rejects points above the 1-100 range', () async {
    await expectLater(
      repository.createTask(validInput(points: 101)),
      throwsA(isA<DatabaseAppException>()),
    );
  });

  test('rejects a task with no category selected', () async {
    await expectLater(
      repository.createTask(validInput(categoryIds: const <int>[])),
      throwsA(isA<DatabaseAppException>()),
    );
  });
}
