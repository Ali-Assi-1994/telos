import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:telos/src/routing/app_routes.dart';

class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({
    required this.currentIndex,
    this.onSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int>? onSelected;

  static const List<_TabItemData> _tabs = <_TabItemData>[
    _TabItemData(
      selectedIcon: Icons.home_rounded,
      unselectedIcon: Icons.home_outlined,
      route: AppRoutes.home,
    ),
    _TabItemData(
      selectedIcon: Icons.inbox_rounded,
      unselectedIcon: Icons.inbox_outlined,
      route: AppRoutes.tasks,
    ),
    _TabItemData(
      selectedIcon: Icons.timer_rounded,
      unselectedIcon: Icons.timer_outlined,
      route: AppRoutes.timer,
    ),
    _TabItemData(
      selectedIcon: Icons.person_rounded,
      unselectedIcon: Icons.person_outline_rounded,
      route: AppRoutes.profile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return CrystalNavigationBar(
      currentIndex: currentIndex,
      onTap: (int index) => _onSelected(context, index),
      enableFloatingNavBar: true,
      height: 92,
      marginR: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      paddingR: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      itemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 999,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.28),
      borderWidth: 0.9,
      outlineBorderColor: colorScheme.surface.withValues(alpha: 0.45),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.03),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      selectedItemColor: colorScheme.onSurface.withValues(alpha: 0.82),
      unselectedItemColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.52),
      indicatorColor: Colors.transparent,
      splashColor: Colors.transparent,
      items: _tabs
          .map(
            (_TabItemData tab) => CrystalNavigationBarItem(
              icon: tab.selectedIcon,
              unselectedIcon: tab.unselectedIcon,
            ),
          )
          .toList(growable: false),
    );
  }

  void _onSelected(BuildContext context, int index) {
    if (index < 0 || index >= _tabs.length || index == currentIndex) {
      return;
    }
    final ValueChanged<int>? onSelectedCallback = onSelected;
    if (onSelectedCallback != null) {
      onSelectedCallback(index);
      return;
    }
    context.go(_tabs[index].route);
  }
}

final class _TabItemData {
  const _TabItemData({
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.route,
  });

  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String route;
}
