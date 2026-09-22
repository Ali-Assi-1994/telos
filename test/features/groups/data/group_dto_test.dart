import 'package:flutter_test/flutter_test.dart';
import 'package:telos/src/features/groups/data/group_dto.dart';
import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/domain/group_member.dart';

void main() {
  group('GroupDto', () {
    test('maps all fields', () {
      final Group group = const GroupDto(<String, dynamic>{
        'id': 'group-1',
        'name': 'Morning Runners',
        'description': 'Early risers keeping each other honest',
        'invite_code': 'ABC123',
        'created_by': 'user-1',
        'created_at': '2026-01-15T09:00:00.000Z',
        'updated_at': '2026-01-15T09:00:00.000Z',
      }).toDomain();

      expect(group.id, 'group-1');
      expect(group.name, 'Morning Runners');
      expect(group.description, 'Early risers keeping each other honest');
      expect(group.inviteCode, 'ABC123');
      expect(group.createdBy, 'user-1');
      expect(group.createdAt, DateTime.parse('2026-01-15T09:00:00.000Z'));
    });

    test('leaves description null when absent', () {
      final Group group = const GroupDto(<String, dynamic>{
        'id': 'group-1',
        'name': 'Morning Runners',
        'invite_code': 'ABC123',
        'created_by': 'user-1',
        'created_at': '2026-01-15T09:00:00.000Z',
        'updated_at': '2026-01-15T09:00:00.000Z',
      }).toDomain();

      expect(group.description, isNull);
    });
  });

  group('GroupMemberDto', () {
    test('maps a full row with nested profile', () {
      final GroupMember member = const GroupMemberDto(<String, dynamic>{
        'group_id': 'group-1',
        'user_id': 'user-1',
        'role': 'admin',
        'joined_at': '2026-01-15T09:00:00.000Z',
        'profiles': <String, dynamic>{
          'username': 'alisouli',
          'display_name': 'Ali',
          'avatar_url': null,
        },
      }).toDomain();

      expect(member.groupId, 'group-1');
      expect(member.userId, 'user-1');
      expect(member.role, GroupRole.admin);
      expect(member.username, 'alisouli');
      expect(member.displayName, 'Ali');
    });

    test('defaults role to member and falls back when profile is missing', () {
      final GroupMember member = const GroupMemberDto(<String, dynamic>{
        'group_id': 'group-1',
        'user_id': 'user-2',
        'role': 'member',
        'joined_at': '2026-01-15T09:00:00.000Z',
      }).toDomain();

      expect(member.role, GroupRole.member);
      expect(member.username, 'unknown');
      expect(member.displayName, isNull);
    });
  });
}
