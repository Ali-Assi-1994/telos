import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final AsyncValue<void> result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signUpWithPassword(
            fullName: fullName.trim(),
            email: email.trim().toLowerCase(),
            password: password,
          ),
    );
    if (!ref.mounted) return;
    state = result;
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final AsyncValue<void> result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithPassword(
            email: email.trim().toLowerCase(),
            password: password,
          ),
    );
    if (!ref.mounted) return;
    state = result;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final AsyncValue<void> result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
    if (!ref.mounted) return;
    state = result;
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    final AsyncValue<void> result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithApple(),
    );
    if (!ref.mounted) return;
    state = result;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final AsyncValue<void> result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
    if (!ref.mounted) return;
    state = result;
  }
}
