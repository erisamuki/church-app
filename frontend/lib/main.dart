import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'utils/theme.dart';
import 'utils/app_router.dart';

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
      child: BCCApp(authProvider: authProvider),
    ),
  );
}

class BCCApp extends StatefulWidget {
  final AuthProvider authProvider;
  const BCCApp({super.key, required this.authProvider});

  @override
  State<BCCApp> createState() => _BCCAppState();
}

class _BCCAppState extends State<BCCApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.build(widget.authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BCC - Blessed Christian Church',
      debugShowCheckedModeBanner: false,
      theme: BCCTheme.lightTheme,
      darkTheme: BCCTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
