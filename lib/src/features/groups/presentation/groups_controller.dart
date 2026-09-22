import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:telos/src/features/auth/presentation/auth_state_provider.dart';
import 'package:telos/src/features/groups/data/supabase_group_repository.dart';
import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/presentation/groups_providers.dart';
import 'package:telos/src/utils/logger.dart';

part 'groups_controller.g.dart';

@riverpod
class GroupsController extends _$GroupsController {
  @override
  FutureOr<void> build() {}

  Future<Group?> createGroup({
    required String name,
    String? description,
  }) async {
    state = const AsyncLoading();
    Group? createdGroup;

    final AsyncValue<void> result = await AsyncValue.guard(() async {
      final user = await ref.read(authStateProvider.future);
      if (user == null) {
        throw StateError('User must be authenticated to create a group.');
      }
      createdGroup = await ref
          .read(groupRepositoryProvider)
          .createGroup(name: name, description: description, userId: user.id);
    });

    if (!ref.mounted) return null;
    state = result;

    if (!state.hasError) {
      ref.invalidate(myGroupsProvider);
      AppLogger.groups.info('Group create mutation completed.');
      return createdGroup;
    }
    return null;
  }

  Future<Group?> joinGroupByCode(String inviteCode) async {
    state = const AsyncLoading();
    Group? joinedGroup;

    final AsyncValue<void> result = await AsyncValue.guard(() async {
      final user = await ref.read(authStateProvider.future);
      if (user == null) {
        throw StateError('User must be authenticated to join a group.');
      }
      joinedGroup = await ref
          .read(groupRepositoryProvider)
          .joinGroupByCode(inviteCode: inviteCode, userId: user.id);
    });

    if (!ref.mounted) return null;
    state = result;

    if (!state.hasError) {
      ref.invalidate(myGroupsProvider);
      AppLogger.groups.info('Group join mutation completed.');
      return joinedGroup;
    }
    return null;
  }

  Future<bool> leaveGroup(String groupId) async {
    state = const AsyncLoading();

    final AsyncValue<void> result = await AsyncValue.guard(() async {
      final user = await ref.read(authStateProvider.future);
      if (user == null) {
        throw StateError('User must be authenticated to leave a group.');
      }
      await ref
          .read(groupRepositoryProvider)
          .leaveGroup(groupId: groupId, userId: user.id);
    });

    if (!ref.mounted) return false;
    state = result;

    if (!state.hasError) {
      ref.invalidate(myGroupsProvider);
      ref.invalidate(groupMembersProvider(groupId));
      AppLogger.groups.info('Left group $groupId.');
      return true;
    }
    return false;
  }
}
