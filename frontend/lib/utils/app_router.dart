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
import '../screens/search_screen.dart';
import '../screens/volunteers_screen.dart';
import '../screens/ministers_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter build(AuthProvider auth) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final isLoginRoute = state.matchedLocation == '/';

        // Unauthenticated users are redirected to login
        if (!auth.isAuthenticated && !isLoginRoute) return '/';
        // Authenticated users are redirected away from login to dashboard
        if (auth.isAuthenticated && isLoginRoute) return '/dashboard';

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/volunteers',
          builder: (context, state) => const VolunteersScreen(),
        ),
        GoRoute(
          path: '/checkin',
          builder: (context, state) => const EventPickerScreen(),
        ),
        GoRoute(
          path: '/giving',
          builder: (context, state) => const GivingScreen(),
        ),
        GoRoute(
          path: '/leadership',
          builder: (context, state) => const MinistersScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/events',
          builder: (context, state) => const EventsScreen(),
        ),

        // Nested/Hierarchical Member Routes
        GoRoute(
          path: '/members',
          builder: (context, state) => const MembersListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const AddMemberScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return MemberDetailScreen(memberId: id);
              },
            ),
          ],
        ),
      ],
      // Fallback route handling for unmatched paths
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.error}'),
        ),
      ),
    );
  }
}
