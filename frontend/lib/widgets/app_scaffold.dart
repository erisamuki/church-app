import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const AppScaffold({super.key, required this.title, required this.body, this.actions});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E293B)),
              accountName: Text(user?.fullName ?? 'User'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: const Color(0xFF3B82F6),
                child: Text(
                  user?.initials ?? 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            _DrawerItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard'),
            _DrawerItem(icon: Icons.people_outline, label: 'Members', route: '/members'),
            _DrawerItem(icon: Icons.event_outlined, label: 'Events', route: '/events'),
            _DrawerItem(
              icon: Icons.volunteer_activism_outlined,
              label: 'Volunteers',
              route: '/events',
            ),
            _DrawerItem(icon: Icons.attach_money_outlined, label: 'Giving', route: '/events'),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                context.read<AuthProvider>().logout();
                context.go('/');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: body,
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _DrawerItem({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    final isActive = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF334155),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? const Color(0xFFEFF6FF) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context); // close the drawer first
        context.go(route);
      },
    );
  }
}
