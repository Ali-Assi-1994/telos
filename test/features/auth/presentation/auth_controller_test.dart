import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/auth/data/supabase_auth_repository.dart';
import 'package:telos/src/features/auth/presentation/auth_controller.dart';

import '../data/fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository authRepository;
  late ProviderContainer container;

  setUp(() {
    authRepository = FakeAuthRepository();
    container = ProviderContainer(
      // Match the app's retry: null (main.dart) so errors surface
      // immediately instead of Riverpod 3's default auto-retry.
      retry: (int retryCount, Object error) => null,
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
    );
    addTearDown(container.dispose);
    // Keep the autoDispose controller alive across awaits, the way the real
    // screens' ref.watch(authControllerProvider) does.
    container.listen(authControllerProvider, (_, _) {});
  });

  test('signIn success clears loading and leaves no error', () async {
    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'user@example.com', password: 'password123');

    final AsyncValue<void> state = container.read(authControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.hasError, isFalse);
    expect(authRepository.currentUser, isNotNull);
  });

  test(
    'signIn failure surfaces AuthAppException with the friendly message',
    () async {
      authRepository.failNextAuth = true;
      authRepository.failureMessage =
          'Invalid email or password. Please try again.';

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'user@example.com', password: 'wrong-password');

      final AsyncValue<void> state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      final Object? error = state.error;
      expect(error, isA<AuthAppException>());
      expect(
        (error! as AuthAppException).toUserMessage(),
        'Invalid email or password. Please try again.',
      );
      expect(authRepository.currentUser, isNull);
    },
  );

  test('signUp success stores a session', () async {
    await container
        .read(authControllerProvider.notifier)
        .signUp(
          fullName: 'Ada Lovelace',
          email: 'ada@example.com',
          password: 'password123',
        );

    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(authRepository.currentUser, isNotNull);
  });

  test('signOut clears the session', () async {
    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'user@example.com', password: 'password123');
    expect(authRepository.currentUser, isNotNull);

    await container.read(authControllerProvider.notifier).signOut();

    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(authRepository.currentUser, isNull);
  });
}
