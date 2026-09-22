// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
// The ProviderScope built by buildApp() below is the root scope for the
// widget tree under test (it's passed straight to tester.pumpWidget), but
// riverpod_lint can't trace that through the helper function indirection and
// conservatively warns as if it might be a nested scope.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';
import 'package:telos/src/features/groups/data/supabase_group_repository.dart';
import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/domain/group_member.dart';
import 'package:telos/src/features/groups/presentation/groups_screen.dart';

import '../../auth/data/fakes/fake_auth_repository.dart';
import '../data/fakes/fake_group_repository.dart';

void main() {
  const AppUser testUser = AppUser(id: 'user-1', email: 'user@example.com');

  Widget buildApp(FakeGroupRepository groupRepository) {
    return ProviderScope(
      // Match the app's retry: null (main.dart) so errors surface
      // immediately instead of Riverpod 3's default auto-retry.
      retry: (int retryCount, Object error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(initialUser: testUser),
        ),
        groupRepositoryProvider.overrideWithValue(groupRepository),
      ],
      child: const MaterialApp(home: GroupsScreen()),
    );
  }

  testWidgets('shows an encouraging empty state with no groups', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(FakeGroupRepository()));
    await tester.pumpAndSettle();

    expect(
      find.text('No groups yet. Create one or join with an invite code!'),
      findsOneWidget,
    );
  });

  testWidgets('shows a group the user belongs to', (
    WidgetTester tester,
  ) async {
    final FakeGroupRepository groupRepository = FakeGroupRepository();
    final DateTime now = DateTime(2026, 1, 15);
    final Group group = Group(
      id: 'group-1',
      name: 'Morning Runners',
      inviteCode: 'ABC123',
      createdBy: testUser.id,
      createdAt: now,
      updatedAt: now,
    );
    groupRepository.seedGroup(
      group,
      members: [
        GroupMember(
          groupId: group.id,
          userId: testUser.id,
          role: GroupRole.admin,
          joinedAt: now,
          username: testUser.id,
        ),
      ],
    );

    await tester.pumpWidget(buildApp(groupRepository));
    await tester.pumpAndSettle();

    expect(find.text('Morning Runners'), findsOneWidget);
  });
}
