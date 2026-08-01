import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/members/members_list_screen.dart';
import '../screens/members/member_detail_screen.dart';
import '../screens/members/add_member_screen.dart';
import '../screens/events_screen.dart';
import '../screens/attendance_checkin_screen.dart';
import '../screens/giving_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter build(AuthProvider auth) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final isLoginRoute = state.matchedLocation == '/';

        if (!auth.isAuthenticated && !isLoginRoute) return '/';
        if (auth.isAuthenticated && isLoginRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/checkin', builder: (context, state) => const EventPickerScreen()),
        GoRoute(path: '/giving', builder: (context, state) => const GivingScreen()),
        GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
        GoRoute(path: '/members', builder: (context, state) => const MembersListScreen()),
        GoRoute(path: '/members/new', builder: (context, state) => const AddMemberScreen()),
        GoRoute(
          path: '/members/:id',
          builder: (context, state) => MemberDetailScreen(memberId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/events', builder: (context, state) => const EventsScreen()),
      ],
    );
  }
}
