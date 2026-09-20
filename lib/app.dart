import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:telos/src/constants/app_colors.dart';
import 'package:telos/src/routing/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final ColorScheme calmColorScheme =
        const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.calmPrimary,
          onPrimary: AppColors.calmPrimaryForeground,
          secondary: AppColors.calmSecondary,
          onSecondary: AppColors.calmSecondaryForeground,
          error: Color(0xFFB42318),
          onError: Colors.white,
          surface: AppColors.calmCard,
          onSurface: AppColors.calmForeground,
        ).copyWith(
          onSurfaceVariant: AppColors.calmMutedForeground,
          secondaryContainer: AppColors.calmSecondary,
          onSecondaryContainer: AppColors.calmSecondaryForeground,
          tertiary: AppColors.calmAccent,
          tertiaryContainer: AppColors.calmAccent,
          onTertiaryContainer: AppColors.calmAccentForeground,
          outline: AppColors.calmBorder,
          outlineVariant: AppColors.calmBorder,
        );

    return MaterialApp.router(
      title: 'Telos',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        colorScheme: calmColorScheme,
        scaffoldBackgroundColor: AppColors.calmBackground,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
