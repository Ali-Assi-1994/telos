/// Base application exception type used across the app.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// Message that can be safely shown to the user (after optional mapping).
  final String message;

  /// Optional underlying error for logging/diagnostics.
  final Object? cause;

  /// Override this when a subtype needs a custom user-facing message.
  String toUserMessage() => message;
}

/// Auth-related errors (login, signup, session).
class AuthAppException extends AppException {
  const AuthAppException(super.message, {Object? cause});

  @override
  String toUserMessage() => message;
}

/// Database and repository operation failures.
class DatabaseAppException extends AppException {
  const DatabaseAppException(super.message, {Object? cause});

  @override
  String toUserMessage() => message;
}

/// Generic unknown error, used as a fallback.
class UnknownAppException extends AppException {
  const UnknownAppException({super.cause})
    : super('Something went wrong. Please try again.');
}
