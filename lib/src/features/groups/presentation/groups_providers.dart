import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:telos/src/features/auth/presentation/auth_state_provider.dart';
import 'package:telos/src/features/groups/data/supabase_group_repository.dart';
import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/domain/group_member.dart';

part 'groups_providers.g.dart';

@riverpod
Future<List<Group>> myGroups(Ref ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return <Group>[];

  return ref.read(groupRepositoryProvider).getMyGroups(userId: user.id);
}

@riverpod
Future<Group> groupDetail(Ref ref, String groupId) {
  return ref.read(groupRepositoryProvider).getGroupById(groupId: groupId);
}

@riverpod
Future<List<GroupMember>> groupMembers(Ref ref, String groupId) {
  return ref.read(groupRepositoryProvider).getGroupMembers(groupId: groupId);
}
