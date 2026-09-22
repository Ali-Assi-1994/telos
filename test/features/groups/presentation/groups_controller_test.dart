import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';
import 'package:telos/src/features/auth/presentation/auth_state_provider.dart';
import 'package:telos/src/features/groups/data/supabase_group_repository.dart';
import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/domain/group_member.dart';
import 'package:telos/src/features/groups/presentation/groups_controller.dart';

import '../../auth/data/fakes/fake_auth_repository.dart';
import '../data/fakes/fake_group_repository.dart';

void main() {
  late FakeGroupRepository groupRepository;
  late FakeAuthRepository authRepository;
  late ProviderContainer container;

  const AppUser testUser = AppUser(id: 'user-1', email: 'user@example.com');
  const AppUser otherUser = AppUser(id: 'user-2', email: 'other@example.com');

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
    // Keep the autoDispose controller alive across awaits, the way a widget's
    // ref.listen would in the real app.
    container.listen(groupsControllerProvider, (_, _) {});
    container.listen(authStateProvider, (_, _) {});
  });

  group('createGroup', () {
    test('creates a group and adds the creator as admin', () async {
      final Group? created = await container
          .read(groupsControllerProvider.notifier)
          .createGroup(name: 'Morning Runners', description: 'Run club');

      expect(container.read(groupsControllerProvider).hasError, isFalse);
      expect(created, isNotNull);
      expect(created!.name, 'Morning Runners');
      expect(groupRepository.groups, hasLength(1));

      final List<GroupMember> members =
          groupRepository.membersByGroupId[created.id]!;
      expect(members.single.userId, testUser.id);
      expect(members.single.role, GroupRole.admin);
    });

    test(
      'repository failure surfaces as an AppException and returns null',
      () async {
        groupRepository.throwOnCreateGroup = true;

        final Group? created = await container
            .read(groupsControllerProvider.notifier)
            .createGroup(name: 'Morning Runners');

        expect(created, isNull);
        final AsyncValue<void> state = container.read(groupsControllerProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<DatabaseAppException>());
      },
    );
  });

  group('joinGroupByCode', () {
    test('joins an existing group by its invite code', () async {
      final Group group = await groupRepository.createGroup(
        name: 'Morning Runners',
        userId: otherUser.id,
      );

      final Group? joined = await container
          .read(groupsControllerProvider.notifier)
          .joinGroupByCode(group.inviteCode);

      expect(container.read(groupsControllerProvider).hasError, isFalse);
      expect(joined?.id, group.id);
      expect(
        groupRepository.membersByGroupId[group.id]!.map(
          (GroupMember m) => m.userId,
        ),
        containsAll(<String>[otherUser.id, testUser.id]),
      );
    });

    test('an invalid code surfaces as an AppException', () async {
      final Group? joined = await container
          .read(groupsControllerProvider.notifier)
          .joinGroupByCode('NOPE99');

      expect(joined, isNull);
      final AsyncValue<void> state = container.read(groupsControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<DatabaseAppException>());
    });
  });

  group('leaveGroup', () {
    test(
      'removes the signed-in user from the group and returns true',
      () async {
        final Group group = await groupRepository.createGroup(
          name: 'Morning Runners',
          userId: testUser.id,
        );

        final bool result = await container
            .read(groupsControllerProvider.notifier)
            .leaveGroup(group.id);

        expect(result, isTrue);
        expect(groupRepository.membersByGroupId[group.id], isEmpty);
      },
    );

    test(
      'repository failure surfaces as an AppException and returns false',
      () async {
        final Group group = await groupRepository.createGroup(
          name: 'Morning Runners',
          userId: testUser.id,
        );
        groupRepository.throwOnLeaveGroup = true;

        final bool result = await container
            .read(groupsControllerProvider.notifier)
            .leaveGroup(group.id);

        expect(result, isFalse);
        final AsyncValue<void> state = container.read(groupsControllerProvider);
        expect(state.hasError, isTrue);
      },
    );
  });
}
