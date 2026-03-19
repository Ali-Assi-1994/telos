import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_auth_repository.dart';

part 'auth_state_provider.g.dart';

/// Current auth state. [User] when signed in, null when signed out.
@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges.map((s) => s?.user);
}
