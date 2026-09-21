import 'package:telos/src/features/tasks/domain/category.dart';
import 'package:telos/src/features/tasks/domain/task.dart';

class CategoryDto {
  const CategoryDto(this.json);

  final Map<String, dynamic> json;

  Category toDomain() {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }
}

class TaskDto {
  const TaskDto(this.json);

  final Map<String, dynamic> json;

  Task toDomain() {
    final List<dynamic> rawTaskCategories =
        (json['task_categories'] as List<dynamic>?) ?? <dynamic>[];
    final List<Category> categories = rawTaskCategories
        .map(
          (dynamic item) =>
              (item as Map<String, dynamic>)['categories']
                  as Map<String, dynamic>?,
        )
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> categoryJson) =>
              CategoryDto(categoryJson).toDomain(),
        )
        .toList(growable: false);

    return Task(
      id: json['id'] as String,
      templateId: json['template_id'] as String?,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      points: json['points'] as int,
      assignedDate: DateTime.parse(json['assigned_date'] as String),
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      isLocked: json['is_locked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      categories: categories,
    );
  }
}
