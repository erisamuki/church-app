import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth provider and check for stored session
  final authProvider = AuthProvider(
    baseUrl: 'http://localhost:3000/api', // Change to your Node.js API URL
  );
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        // Add other providers here as you build them
        // ChangeNotifierProvider(create: (_) => MembersProvider()),
        // ChangeNotifierProvider(create: (_) => EventsProvider()),
        // ChangeNotifierProvider(create: (_) => FinanceProvider()),
      ],
      child: const BCCApp(),
    ),
  );
}

class BCCApp extends StatelessWidget {
  const BCCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BCC - Blessed Christian Church',
      debugShowCheckedModeBanner: false,
      theme: BCCTheme.lightTheme,
      darkTheme: BCCTheme.darkTheme,
      themeMode: ThemeMode.light, // Or use system/provider-based switching
      home: const AuthGate(),
    );
  }
}

/// Routes users based on authentication state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show loading while checking auth state
        if (auth.isLoading && auth.user == null) {
          return const Scaffold(
            backgroundColor: BCCTheme.black,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(BCCTheme.orange),
              ),
            ),
          );
        }

        // Route to dashboard if authenticated, login if not
        return auth.isAuthenticated ? const DashboardScreen() : const LoginScreen();
      },
    );
  }
}

