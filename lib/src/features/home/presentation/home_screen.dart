import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/auth/presentation/auth_controller.dart';
import 'package:telos/src/routing/app_routes.dart';

/// Placeholder home screen after login. Tasks list will be added here.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text('You\'re in. Tasks will go here.'),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.groups),
              icon: const Icon(Icons.groups_rounded),
              label: const Text('Groups'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    // Success: auth state will update and router redirects to login.
    if (!context.mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((state.error! as AppException).toUserMessage()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
