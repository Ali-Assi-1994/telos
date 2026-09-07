import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';

part 'auth_state_provider.g.dart';

/// Current auth state. [AppUser] when signed in, null when signed out.
@riverpod
Stream<AppUser?> authState(AuthStateRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}
