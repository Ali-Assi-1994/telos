import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract for authentication operations.
///
/// Implementations use Supabase Auth; callers receive domain-friendly
/// results or [AppException] on failure.
abstract class AuthRepository {
  /// Stream of auth state changes. Emits [Session?] (null when signed out).
  Stream<Session?> get authStateChanges;

  /// Current session if signed in.
  Session? get currentSession;

  /// Signs in with email and password.
  /// Throws [AuthAppException] on invalid credentials or network error.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Starts a sign-in flow with Google.
  ///
  /// Throws [AuthAppException] on failure or if the flow cannot be started.
  Future<void> signInWithGoogle();

  /// Starts a sign-in flow with Apple.
  ///
  /// Throws [AuthAppException] on failure or if the flow cannot be started.
  Future<void> signInWithApple();

  /// Signs out the current user.
  Future<void> signOut();
}
