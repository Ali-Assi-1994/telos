import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/services/supabase_service.dart';
import 'package:telos/src/utils/logger.dart';
import 'package:telos/src/features/auth/data/auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';

part 'supabase_auth_repository.g.dart';

/// Supabase-backed implementation of [AuthRepository].
///
/// Maps [AuthException] to [AuthAppException] with user-friendly messages,
/// and Supabase's [User] to the app's own [AppUser] so no other layer needs
/// to know the SDK type exists.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<AppUser?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((e) => _toAppUser(e.session?.user));

  @override
  AppUser? get currentUser => _toAppUser(_client.auth.currentSession?.user);

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email,
      fullName: user.userMetadata?['full_name'] as String?,
    );
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      AppLogger.auth.info('Sign-in success: ${email.trim().toLowerCase()}');
    } on AuthException catch (e, st) {
      AppLogger.auth.error('Sign-in failed', error: e, stackTrace: st);
      throw AuthAppException(_mapAuthError(e.message), cause: e);
    }
  }

  @override
  Future<void> signUpWithPassword({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      AppLogger.auth.info('Sign-up success: ${email.trim().toLowerCase()}');
    } on AuthException catch (e, st) {
      AppLogger.auth.error('Sign-up failed', error: e, stackTrace: st);
      throw AuthAppException(_mapSignUpError(e.message), cause: e);
    }
  }

  @override
  Future<void> signInWithGoogle() => _signInWithOAuth(OAuthProvider.google);

  @override
  Future<void> signInWithApple() => _signInWithOAuth(OAuthProvider.apple);

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    try {
      await _client.auth.signInWithOAuth(provider);
      AppLogger.auth.info('OAuth sign-in started: $provider');
    } on AuthException catch (e, st) {
      AppLogger.auth.error('OAuth sign-in failed', error: e, stackTrace: st);
      throw AuthAppException(_mapAuthError(e.message), cause: e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      AppLogger.auth.info('Signed out');
    } on AuthException catch (e, st) {
      AppLogger.auth.error('Sign-out failed', error: e, stackTrace: st);
      throw AuthAppException(_mapAuthError(e.message), cause: e);
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Connection problem. Check your network and try again.';
    }
    return 'Sign-in failed. Please try again.';
  }

  String _mapSignUpError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('user already registered') ||
        lower.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('password')) {
      return 'Please choose a stronger password and try again.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Connection problem. Check your network and try again.';
    }
    return 'Sign-up failed. Please try again.';
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    SupabaseAuthRepository(ref.watch(supabaseClientProvider));
