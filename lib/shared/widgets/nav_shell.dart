import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../features/auth/providers/auth_provider.dart';

final class NavShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const NavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).user?.role ?? UserRole.student;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _NavBar(
        navigationShell: navigationShell,
        role: role,
      ),
    );
  }
}

final class _NavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final UserRole role;

  const _NavBar({required this.navigationShell, required this.role});

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    final tabs = _tabsForRole(role);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: index >= tabs.length ? 0 : index,
        onTap: (i) => navigationShell.goBranch(i, initialLocation: i == index),
        items: tabs.map((t) => BottomNavigationBarItem(
          icon: Icon(t.icon),
          activeIcon: Icon(t.activeIcon),
          label: t.label,
        )).toList(),
      ),
    );
  }
}

final class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabItem(this.label, this.icon, this.activeIcon);
}

List<_TabItem> _tabsForRole(UserRole role) {
  return switch (role) {
    UserRole.startup => const [
      _TabItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
      _TabItem('Opportunities', Icons.work_outline, Icons.work),
      _TabItem('Applicants', Icons.people_outline, Icons.people),
      _TabItem('Profile', Icons.business_outlined, Icons.business),
    ],
    UserRole.admin => const [
      _TabItem('Verify', Icons.verified_outlined, Icons.verified),
      _TabItem('Users', Icons.group_outlined, Icons.group),
      _TabItem('', Icons.radio_button_unchecked, Icons.radio_button_checked),
      _TabItem('Profile', Icons.person_outline, Icons.person),
    ],
    _ => const [
      _TabItem('Home', Icons.home_outlined, Icons.home),
      _TabItem('Applications', Icons.description_outlined, Icons.description),
      _TabItem('Bookmarks', Icons.bookmark_outline, Icons.bookmark),
      _TabItem('Profile', Icons.person_outline, Icons.person),
    ],
  };
}
