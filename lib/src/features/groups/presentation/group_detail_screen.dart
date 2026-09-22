import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/domain/group_member.dart';
import 'package:telos/src/features/groups/presentation/groups_controller.dart';
import 'package:telos/src/features/groups/presentation/groups_providers.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(groupsControllerProvider, (_, state) {
      if (state.hasError) {
        _showMessage(_errorMessage(state.error));
      }
    });

    final AsyncValue<Group> groupState = ref.watch(
      groupDetailProvider(widget.groupId),
    );
    final bool isMutating = ref.watch(
      groupsControllerProvider.select((AsyncValue<void> s) => s.isLoading),
    );

    return Scaffold(
      appBar: AppBar(
        title: groupState.when(
          data: (Group group) => Text(group.name),
          loading: () => const Text('Group'),
          error: (Object _, StackTrace _) => const Text('Group'),
        ),
      ),
      body: SafeArea(
        child: groupState.when(
          data: (Group group) =>
              _GroupDetailBody(group: group, isLeaving: isMutating, onLeave: _confirmLeave),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _errorMessage(error),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Leave group?'),
        content: const Text(
          "You'll lose access to this group's leaderboard until you rejoin.",
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final bool left = await ref
        .read(groupsControllerProvider.notifier)
        .leaveGroup(widget.groupId);
    if (!mounted) return;
    if (left && context.canPop()) {
      context.pop();
    }
  }

  String _errorMessage(Object? error) {
    if (error is AppException) return error.toUserMessage();
    return 'Something went wrong. Please try again.';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GroupDetailBody extends ConsumerWidget {
  const _GroupDetailBody({
    required this.group,
    required this.isLeaving,
    required this.onLeave,
  });

  final Group group;
  final bool isLeaving;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<GroupMember>> membersState = ref.watch(
      groupMembersProvider(group.id),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        if (group.description != null && group.description!.isNotEmpty) ...<Widget>[
          Text(group.description!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
        ],
        _InviteCodeCard(inviteCode: group.inviteCode),
        const SizedBox(height: 24),
        Text(
          'Members',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        membersState.when(
          data: (List<GroupMember> members) => Column(
            children: members
                .map((GroupMember member) => _MemberTile(member: member))
                .toList(growable: false),
          ),
          loading: () =>
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          error: (Object error, StackTrace _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              error is AppException
                  ? error.toUserMessage()
                  : 'Could not load members.',
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: isLeaving ? null : onLeave,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(isLeaving ? 'Leaving...' : 'Leave group'),
        ),
      ],
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.inviteCode});

  final String inviteCode;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Invite code',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inviteCode,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              color: colorScheme.onSecondaryContainer,
              tooltip: 'Copy invite code',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: inviteCode));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final GroupMember member;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String label = member.displayName?.isNotEmpty == true
        ? member.displayName!
        : member.username;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          label.isEmpty ? '?' : label[0].toUpperCase(),
          style: TextStyle(color: colorScheme.onPrimaryContainer),
        ),
      ),
      title: Text(label),
      subtitle: Text('@${member.username}'),
      trailing: member.role == GroupRole.admin
          ? Chip(
              label: const Text('Admin'),
              backgroundColor: colorScheme.tertiaryContainer,
              labelStyle: TextStyle(color: colorScheme.onTertiaryContainer),
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }
}
