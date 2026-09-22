import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/groups/data/group_repository.dart';
import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/domain/group_member.dart';

/// In-memory [GroupRepository] fake for controller and widget tests.
class FakeGroupRepository implements GroupRepository {
  final List<Group> groups = <Group>[];
  final Map<String, List<GroupMember>> membersByGroupId =
      <String, List<GroupMember>>{};

  bool throwOnGetMyGroups = false;
  bool throwOnGetGroupById = false;
  bool throwOnGetGroupMembers = false;
  bool throwOnCreateGroup = false;
  bool throwOnJoinGroupByCode = false;
  bool throwOnLeaveGroup = false;

  int _idCounter = 0;

  void seedGroup(Group group, {List<GroupMember> members = const []}) {
    groups.add(group);
    membersByGroupId[group.id] = List<GroupMember>.of(members);
  }

  @override
  Future<List<Group>> getMyGroups({required String userId}) async {
    if (throwOnGetMyGroups) {
      throw const DatabaseAppException(
        'Could not load your groups right now. Please try again.',
      );
    }
    return groups
        .where(
          (Group group) => (membersByGroupId[group.id] ?? const [])
              .any((GroupMember m) => m.userId == userId),
        )
        .toList(growable: false);
  }

  @override
  Future<Group> getGroupById({required String groupId}) async {
    if (throwOnGetGroupById) {
      throw const DatabaseAppException(
        'Could not load this group right now. Please try again.',
      );
    }
    return groups.firstWhere((Group g) => g.id == groupId);
  }

  @override
  Future<List<GroupMember>> getGroupMembers({required String groupId}) async {
    if (throwOnGetGroupMembers) {
      throw const DatabaseAppException(
        'Could not load group members right now. Please try again.',
      );
    }
    return List<GroupMember>.of(membersByGroupId[groupId] ?? const []);
  }

  @override
  Future<Group> createGroup({
    required String name,
    String? description,
    required String userId,
  }) async {
    if (throwOnCreateGroup) {
      throw const DatabaseAppException(
        'Could not create group right now. Please try again.',
      );
    }
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const DatabaseAppException('Group name is required.');
    }

    _idCounter += 1;
    final DateTime now = DateTime(2026, 1, 15);
    final Group group = Group(
      id: 'group-$_idCounter',
      name: trimmedName,
      description: description,
      inviteCode: 'CODE${_idCounter.toString().padLeft(2, '0')}',
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );
    seedGroup(
      group,
      members: <GroupMember>[
        GroupMember(
          groupId: group.id,
          userId: userId,
          role: GroupRole.admin,
          joinedAt: now,
          username: userId,
        ),
      ],
    );
    return group;
  }

  @override
  Future<Group> joinGroupByCode({
    required String inviteCode,
    required String userId,
  }) async {
    if (throwOnJoinGroupByCode) {
      throw const DatabaseAppException('Could not join this group.');
    }

    final Group group = groups.firstWhere(
      (Group g) => g.inviteCode == inviteCode.trim().toUpperCase(),
      orElse: () => throw const DatabaseAppException('Invalid invite code'),
    );

    final List<GroupMember> members = membersByGroupId[group.id] ??= [];
    if (members.any((GroupMember m) => m.userId == userId)) {
      throw const DatabaseAppException('You are already in this group');
    }
    members.add(
      GroupMember(
        groupId: group.id,
        userId: userId,
        role: GroupRole.member,
        joinedAt: DateTime(2026, 1, 15),
        username: userId,
      ),
    );
    return group;
  }

  @override
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    if (throwOnLeaveGroup) {
      throw const DatabaseAppException(
        'Could not leave this group right now. Please try again.',
      );
    }
    membersByGroupId[groupId]?.removeWhere(
      (GroupMember m) => m.userId == userId,
    );
  }
}
