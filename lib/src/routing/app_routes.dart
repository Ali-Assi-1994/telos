/// Central definition of all route path constants.
///
/// Keep this file free of any widget imports.
final class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';

  // Auth
  static const String authRoot = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Tasks
  static const String tasks = '/tasks';
  static const String taskCreate = '/tasks/create';
  static const String taskEdit = '/tasks/edit';
  static const String timer = '/timer';
  static const String profile = '/profile';

  // Groups
  static const String groups = '/groups';
  static const String groupDetail = '/groups/detail';

  // Leaderboard
  static const String leaderboard = '/leaderboard';
}
