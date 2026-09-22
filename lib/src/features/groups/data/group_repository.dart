import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/domain/group_member.dart';

abstract class GroupRepository {
  Future<List<Group>> getMyGroups({required String userId});

  Future<Group> getGroupById({required String groupId});

  Future<List<GroupMember>> getGroupMembers({required String groupId});

  Future<Group> createGroup({
    required String name,
    String? description,
    required String userId,
  });

  Future<Group> joinGroupByCode({
    required String inviteCode,
    required String userId,
  });

  Future<void> leaveGroup({required String groupId, required String userId});
}
