import 'package:telos/src/features/auth/domain/app_user.dart';

/// Contract for authentication operations.
///
/// Implementations use Supabase Auth; callers receive domain-friendly
/// results or [AppException] on failure.
abstract class AuthRepository {
  /// Stream of auth state changes. Emits `null` when signed out.
  Stream<AppUser?> get authStateChanges;

  /// Current user if signed in.
  AppUser? get currentUser;

  /// Signs up a new user with email and password.
  ///
  /// Optionally stores [fullName] as user metadata.
  /// Throws [AuthAppException] on failure.
  Future<void> signUpWithPassword({
    required String fullName,
    required String email,
    required String password,
  });

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
