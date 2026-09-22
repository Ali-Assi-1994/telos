import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';
import 'package:telos/src/features/auth/presentation/auth_state_provider.dart';
import 'package:telos/src/features/groups/data/supabase_group_repository.dart';
import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/domain/group_member.dart';
import 'package:telos/src/features/groups/presentation/groups_providers.dart';

import '../../auth/data/fakes/fake_auth_repository.dart';
import '../data/fakes/fake_group_repository.dart';

void main() {
  late FakeGroupRepository groupRepository;
  late FakeAuthRepository authRepository;
  late ProviderContainer container;

  const AppUser testUser = AppUser(id: 'user-1', email: 'user@example.com');

  Group buildGroup(String id) {
    final DateTime now = DateTime(2026, 1, 15);
    return Group(
      id: id,
      name: 'Group $id',
      inviteCode: 'CODE$id',
      createdBy: testUser.id,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    groupRepository = FakeGroupRepository();
    authRepository = FakeAuthRepository(initialUser: testUser);
    container = ProviderContainer(
      // Match the app's retry: null (main.dart) so errors surface
      // immediately instead of Riverpod 3's default auto-retry.
      retry: (int retryCount, Object error) => null,
      overrides: [
        groupRepositoryProvider.overrideWithValue(groupRepository),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(authStateProvider, (_, _) {});
  });

  group('myGroupsProvider', () {
    test('returns only groups the signed-in user belongs to', () async {
      final Group myGroup = buildGroup('1');
      groupRepository.seedGroup(
        myGroup,
        members: [
          GroupMember(
            groupId: myGroup.id,
            userId: testUser.id,
            role: GroupRole.admin,
            joinedAt: DateTime(2026, 1, 15),
            username: testUser.id,
          ),
        ],
      );
      groupRepository.seedGroup(buildGroup('2'));

      final List<Group> result = await container.read(
        myGroupsProvider.future,
      );

      expect(result.map((Group g) => g.id), ['1']);
    });

    test('returns an empty list when signed out', () async {
      await authRepository.signOut();

      final List<Group> result = await container.read(
        myGroupsProvider.future,
      );

      expect(result, isEmpty);
    });
  });

  group('groupDetailProvider', () {
    test('returns the group for the given id', () async {
      groupRepository.seedGroup(buildGroup('1'));

      final Group result = await container.read(
        groupDetailProvider('1').future,
      );

      expect(result.id, '1');
    });
  });

  group('groupMembersProvider', () {
    test('returns the members of the given group', () async {
      final Group group = buildGroup('1');
      groupRepository.seedGroup(
        group,
        members: [
          GroupMember(
            groupId: group.id,
            userId: testUser.id,
            role: GroupRole.admin,
            joinedAt: DateTime(2026, 1, 15),
            username: testUser.id,
          ),
        ],
      );

      final List<GroupMember> result = await container.read(
        groupMembersProvider('1').future,
      );

      expect(result, hasLength(1));
      expect(result.single.userId, testUser.id);
    });
  });
}
