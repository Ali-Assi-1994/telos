import 'dart:async';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/auth/data/auth_repository.dart';
import 'package:telos/src/features/auth/domain/app_user.dart';

/// In-memory [AuthRepository] fake for controller and widget tests.
///
/// Emits [_currentUser] to any new subscriber immediately, then forwards
/// future sign-in/sign-out events, mirroring how Supabase's real
/// `onAuthStateChange` behaves for a client that is already signed in.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser}) : _currentUser = initialUser;

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;

  /// When true, the next auth call throws [AuthAppException] instead of
  /// succeeding.
  bool failNextAuth = false;

  /// Message used when [failNextAuth] is true.
  String failureMessage = 'Invalid email or password. Please try again.';

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signUpWithPassword({
    required String fullName,
    required String email,
    required String password,
  }) => _authenticate(email: email, fullName: fullName);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) => _authenticate(email: email);

  @override
  Future<void> signInWithGoogle() =>
      _authenticate(email: 'google-user@example.com');

  @override
  Future<void> signInWithApple() =>
      _authenticate(email: 'apple-user@example.com');

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  Future<void> _authenticate({required String email, String? fullName}) async {
    if (failNextAuth) {
      throw AuthAppException(failureMessage);
    }
    final AppUser user = AppUser(
      id: 'user-$email',
      email: email,
      fullName: fullName,
    );
    _currentUser = user;
    _controller.add(user);
  }

  void dispose() => _controller.close();
}
