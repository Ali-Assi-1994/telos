import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:telos/src/features/tasks/domain/category.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    String? templateId,
    required String userId,
    required String title,
    String? description,
    required int points,
    required DateTime assignedDate,
    @Default(false) bool completed,
    DateTime? completedAt,
    @Default(false) bool isLocked,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(<Category>[]) List<Category> categories,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
