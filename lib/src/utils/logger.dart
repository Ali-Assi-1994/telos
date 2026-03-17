import 'dart:developer' as developer;

/// Centralized application logger.
///
/// Use the typed loggers (e.g. [AppLogger.auth], [AppLogger.tasks]) instead of
/// `print()` or `developer.log` directly.
final class AppLogger {
  const AppLogger._(this._tag);

  final String _tag;

  static const AppLogger auth = AppLogger._('auth');
  static const AppLogger tasks = AppLogger._('tasks');
  static const AppLogger performance = AppLogger._('performance');
  static const AppLogger groups = AppLogger._('groups');
  static const AppLogger leaderboard = AppLogger._('leaderboard');
  static const AppLogger routing = AppLogger._('routing');
  static const AppLogger services = AppLogger._('services');

  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log('INFO', message, error: error, stackTrace: stackTrace);
  }

  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log('WARN', message, error: error, stackTrace: stackTrace);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, error: error, stackTrace: stackTrace);
  }

  void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logMessage = '[$level][$_tag] $message';
    developer.log(
      logMessage,
      level: _toDeveloperLevel(level),
      error: error,
      stackTrace: stackTrace,
      name: 'Telos',
    );
  }

  int _toDeveloperLevel(String level) {
    switch (level) {
      case 'ERROR':
        return 1000;
      case 'WARN':
        return 900;
      case 'INFO':
      default:
        return 800;
    }
  }
}

