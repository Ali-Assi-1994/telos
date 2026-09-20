import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';

part 'auth_state_provider.g.dart';

/// Current auth state. [AppUser] when signed in, null when signed out.
///
/// keepAlive because it's read one-shot via `ref.read(authStateProvider.future)`
/// in mutation controllers (task_create_controller, task_mutation_controller);
/// as a default autoDispose provider it could be torn down mid-read between
/// those one-shot reads, since a `.read` doesn't keep it alive the way
/// `ref.watch` does.
@Riverpod(keepAlive: true)
Stream<AppUser?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}
