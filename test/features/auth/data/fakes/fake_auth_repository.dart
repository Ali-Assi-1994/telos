import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/auth/data/auth_repository.dart';

/// In-memory [AuthRepository] fake for controller and widget tests.
///
/// Emits [_currentSession] to any new subscriber immediately, then forwards
/// future sign-in/sign-out events, mirroring how Supabase's real
/// `onAuthStateChange` behaves for a client that is already signed in.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({Session? initialSession})
      : _currentSession = initialSession;

  final StreamController<Session?> _controller =
      StreamController<Session?>.broadcast();

  Session? _currentSession;

  /// When true, the next auth call throws [AuthAppException] instead of
  /// succeeding.
  bool failNextAuth = false;

  /// Message used when [failNextAuth] is true.
  String failureMessage = 'Invalid email or password. Please try again.';

  @override
  Stream<Session?> get authStateChanges async* {
    yield _currentSession;
    yield* _controller.stream;
  }

  @override
  Session? get currentSession => _currentSession;

  @override
  Future<void> signUpWithPassword({
    required String fullName,
    required String email,
    required String password,
  }) =>
      _authenticate(email);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _authenticate(email);

  @override
  Future<void> signInWithGoogle() => _authenticate('google-user@example.com');

  @override
  Future<void> signInWithApple() => _authenticate('apple-user@example.com');

  @override
  Future<void> signOut() async {
    _currentSession = null;
    _controller.add(null);
  }

  Future<void> _authenticate(String email) async {
    if (failNextAuth) {
      throw AuthAppException(failureMessage);
    }
    final User user = User(
      id: 'user-$email',
      appMetadata: const <String, dynamic>{},
      userMetadata: const <String, dynamic>{},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    final Session session = Session(
      accessToken: 'fake-access-token',
      tokenType: 'bearer',
      user: user,
    );
    _currentSession = session;
    _controller.add(session);
  }

  void dispose() => _controller.close();
}
