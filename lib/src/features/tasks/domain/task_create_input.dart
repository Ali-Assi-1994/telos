import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_create_input.freezed.dart';
part 'task_create_input.g.dart';

@freezed
class TaskCreateInput with _$TaskCreateInput {
  const factory TaskCreateInput({
    required String userId,
    required String title,
    String? description,
    required int points,
    required DateTime assignedDate,
    required List<int> categoryIds,
  }) = _TaskCreateInput;

  factory TaskCreateInput.fromJson(Map<String, dynamic> json) =>
      _$TaskCreateInputFromJson(json);
}
