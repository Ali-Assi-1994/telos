import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/groups/domain/group.dart';
import 'package:telos/src/features/groups/presentation/groups_controller.dart';
import 'package:telos/src/features/groups/presentation/groups_providers.dart';
import 'package:telos/src/features/groups/presentation/widgets/create_group_sheet.dart';
import 'package:telos/src/features/groups/presentation/widgets/group_card.dart';
import 'package:telos/src/features/groups/presentation/widgets/join_group_sheet.dart';
import 'package:telos/src/routing/app_routes.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(groupsControllerProvider, (_, state) {
      if (state.hasError) {
        _showMessage(_errorMessage(state.error));
      }
    });

    final AsyncValue<List<Group>> groupsState = ref.watch(myGroupsProvider);
    final bool isMutating = ref.watch(
      groupsControllerProvider.select((AsyncValue<void> s) => s.isLoading),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: <Widget>[
          TextButton(
            onPressed: isMutating ? null : _openJoinGroupSheet,
            child: const Text('Join'),
          ),
        ],
      ),
      body: SafeArea(
        child: groupsState.when(
          data: (List<Group> groups) {
            if (groups.isEmpty) {
              return _EmptyGroupsState(onCreate: _openCreateGroupSheet);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final Group group = groups[index];
                return GroupCard(
                  group: group,
                  onTap: () => _openGroupDetail(group.id),
                );
              },
            );
          },
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isMutating ? null : _openCreateGroupSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create group'),
      ),
    );
  }

  void _openGroupDetail(String groupId) {
    context.push('${AppRoutes.groupDetail}/$groupId');
  }

  Future<void> _openCreateGroupSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final bool isLoading = ref.watch(
              groupsControllerProvider.select(
                (AsyncValue<void> s) => s.isLoading,
              ),
            );
            return CreateGroupSheet(
              isLoading: isLoading,
              onCreate:
                  ({required String name, required String? description}) async {
                    final Group? created = await ref
                        .read(groupsControllerProvider.notifier)
                        .createGroup(name: name, description: description);
                    if (!sheetContext.mounted) return;
                    if (created != null) {
                      Navigator.of(sheetContext).pop();
                      _openGroupDetail(created.id);
                    }
                  },
            );
          },
        );
      },
    );
  }

  Future<void> _openJoinGroupSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final bool isLoading = ref.watch(
              groupsControllerProvider.select(
                (AsyncValue<void> s) => s.isLoading,
              ),
            );
            return JoinGroupSheet(
              isLoading: isLoading,
              onJoin: ({required String inviteCode}) async {
                final Group? joined = await ref
                    .read(groupsControllerProvider.notifier)
                    .joinGroupByCode(inviteCode);
                if (!sheetContext.mounted) return;
                if (joined != null) {
                  Navigator.of(sheetContext).pop();
                  _openGroupDetail(joined.id);
                }
              },
            );
          },
        );
      },
    );
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

class _EmptyGroupsState extends StatelessWidget {
  const _EmptyGroupsState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.groups_rounded, size: 56, color: colorScheme.primary),
            const SizedBox(height: 16),
            const Text(
              'No groups yet. Create one or join with an invite code!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Create your first group'),
            ),
          ],
        ),
      ),
    );
  }
}
