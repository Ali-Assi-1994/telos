import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member.freezed.dart';
part 'group_member.g.dart';

enum GroupRole { admin, member }

@freezed
abstract class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String groupId,
    required String userId,
    required GroupRole role,
    required DateTime joinedAt,
    required String username,
    String? displayName,
    String? avatarUrl,
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}
