import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/services/supabase_service.dart';
import 'package:telos/src/utils/logger.dart';
import 'package:telos/src/features/auth/data/auth_repository.dart';

part 'supabase_auth_repository.g.dart';

/// Supabase-backed implementation of [AuthRepository].
///
/// Maps [AuthException] to [AuthAppException] with user-friendly messages.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<Session?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((e) => e.session);

  @override
  Session? get currentSession => _client.auth.currentSession;

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
        data: {
          'full_name': fullName,
        },
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
AuthRepository authRepository(AuthRepositoryRef ref) =>
    SupabaseAuthRepository(ref.watch(supabaseClientProvider));
