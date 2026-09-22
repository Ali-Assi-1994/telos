import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/groups/data/group_dto.dart';
import 'package:telos/src/features/groups/data/group_repository.dart';
import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/domain/group_member.dart';
import 'package:telos/src/services/supabase_service.dart';
import 'package:telos/src/utils/logger.dart';

part 'supabase_group_repository.g.dart';

const String _groupColumns =
    'id,name,description,invite_code,created_by,created_at,updated_at';

@Riverpod(keepAlive: true)
GroupRepository groupRepository(Ref ref) {
  return SupabaseGroupRepository(ref.watch(supabaseClientProvider));
}

class SupabaseGroupRepository implements GroupRepository {
  const SupabaseGroupRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Group>> getMyGroups({required String userId}) async {
    try {
      final List<dynamic> rows = await _client
          .from('group_members')
          .select('groups($_groupColumns)')
          .eq('user_id', userId)
          .order('joined_at');

      return rows
          .map(
            (dynamic row) => GroupDto(
              (row as Map<String, dynamic>)['groups'] as Map<String, dynamic>,
            ).toDomain(),
          )
          .toList(growable: false);
    } on PostgrestException catch (e, st) {
      AppLogger.groups.error(
        'Failed to load groups for user',
        error: e,
        stackTrace: st,
      );
      throw DatabaseAppException(
        'Could not load your groups right now. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<Group> getGroupById({required String groupId}) async {
    try {
      final Map<String, dynamic> row = await _client
          .from('groups')
          .select(_groupColumns)
          .eq('id', groupId)
          .single();

      return GroupDto(row).toDomain();
    } on PostgrestException catch (e, st) {
      AppLogger.groups.error(
        'Failed to load group $groupId',
        error: e,
        stackTrace: st,
      );
      throw DatabaseAppException(
        'Could not load this group right now. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<List<GroupMember>> getGroupMembers({required String groupId}) async {
    try {
      final List<dynamic> rows = await _client
          .from('group_members')
          .select(
            'group_id,user_id,role,joined_at,profiles(username,display_name,avatar_url)',
          )
          .eq('group_id', groupId)
          .order('joined_at');

      return rows
          .map(
            (dynamic row) =>
                GroupMemberDto(row as Map<String, dynamic>).toDomain(),
          )
          .toList(growable: false);
    } on PostgrestException catch (e, st) {
      AppLogger.groups.error(
        'Failed to load members for group $groupId',
        error: e,
        stackTrace: st,
      );
      throw DatabaseAppException(
        'Could not load group members right now. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<Group> createGroup({
    required String name,
    String? description,
    required String userId,
  }) async {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const DatabaseAppException('Group name is required.');
    }

    try {
      final Map<String, dynamic> inserted = await _client
          .from('groups')
          .insert(<String, dynamic>{
            'name': trimmedName,
            'description': description?.trim(),
            'created_by': userId,
          })
          .select(_groupColumns)
          .single();

      final Group group = GroupDto(inserted).toDomain();
      AppLogger.groups.info('Created group: ${group.id}');
      return group;
    } on PostgrestException catch (e, st) {
      AppLogger.groups.error('Failed to create group', error: e, stackTrace: st);
      throw DatabaseAppException(
        'Could not create group right now. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<Group> joinGroupByCode({
    required String inviteCode,
    required String userId,
  }) async {
    final String trimmedCode = inviteCode.trim();
    if (trimmedCode.isEmpty) {
      throw const DatabaseAppException('Enter an invite code.');
    }

    try {
      final dynamic result = await _client.rpc<dynamic>(
        'join_group_by_code',
        params: <String, dynamic>{
          'p_invite_code': trimmedCode,
          'p_user_id': userId,
        },
      );

      if (result is! Map<String, dynamic>) {
        throw const DatabaseAppException(
          'Unexpected server response while joining group.',
        );
      }

      final bool success = result['success'] as bool? ?? false;
      if (!success) {
        final String errorMessage =
            result['error'] as String? ?? 'Could not join this group.';
        throw DatabaseAppException(errorMessage);
      }

      final Group group = GroupDto(
        result['group'] as Map<String, dynamic>,
      ).toDomain();
      AppLogger.groups.info('Joined group: ${group.id}');
      return group;
    } on PostgrestException catch (e, st) {
      AppLogger.groups.error(
        'Failed to join group by code',
        error: e,
        stackTrace: st,
      );
      throw DatabaseAppException(
        'Could not join this group right now. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
      AppLogger.groups.info('Left group: $groupId');
    } on PostgrestException catch (e, st) {
      AppLogger.groups.error(
        'Failed to leave group $groupId',
        error: e,
        stackTrace: st,
      );
      throw DatabaseAppException(
        'Could not leave this group right now. Please try again.',
        cause: e,
      );
    }
  }
}
