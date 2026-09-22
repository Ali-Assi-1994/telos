import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/domain/group_member.dart';

class GroupDto {
  const GroupDto(this.json);

  final Map<String, dynamic> json;

  Group toDomain() {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class GroupMemberDto {
  const GroupMemberDto(this.json);

  final Map<String, dynamic> json;

  GroupMember toDomain() {
    final Map<String, dynamic>? profile =
        json['profiles'] as Map<String, dynamic>?;

    return GroupMember(
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: (json['role'] as String) == 'admin'
          ? GroupRole.admin
          : GroupRole.member,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      username: profile?['username'] as String? ?? 'unknown',
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
