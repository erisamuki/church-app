import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/members/members_list_screen.dart';
import '../screens/members/member_detail_screen.dart';
import '../screens/events/events_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(BuildContext context) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      redirect: (context, state) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final isLoginRoute = state.matchedLocation == '/';

        if (!auth.isAuthenticated && !isLoginRoute) return '/';
        if (auth.isAuthenticated && isLoginRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
        GoRoute(path: '/members', builder: (context, state) => const MembersListScreen()),
        GoRoute(
          path: '/members/:id',
          builder: (context, state) => MemberDetailScreen(memberId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/events', builder: (context, state) => const EventsScreen()),
      ],
    );
  }
}
