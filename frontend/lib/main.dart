import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/sermons_provider.dart';
import 'providers/communications_provider.dart';
import 'utils/theme.dart';
import 'utils/app_router.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth provider with live Render API endpoint
  final authProvider = AuthProvider(
    baseUrl: 'https://church-app-mq1b.onrender.com/api',
  );
  await authProvider.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),

        // Sermons Provider Proxy
        ChangeNotifierProxyProvider<AuthProvider, SermonsProvider>(
          create: (context) => SermonsProvider(
            authProvider: context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) => SermonsProvider(
            authProvider: auth,
          )..fetchSermons(),
        ),

        // Communications Provider Proxy
        ChangeNotifierProxyProvider<AuthProvider, CommunicationsProvider>(
          create: (context) => CommunicationsProvider(
            authProvider: context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) => CommunicationsProvider(
            authProvider: auth,
          )..fetchCommunications(),
        ),
      ],
      child: const BCCApp(),
    ),
  );
}

class BCCApp extends StatefulWidget {
  const BCCApp({super.key});

  @override
  State<BCCApp> createState() => _BCCAppState();
}

class _BCCAppState extends State<BCCApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Access authProvider via context to maintain proper provider lifecycle bindings
    final authProvider = context.read<AuthProvider>();
    _router = AppRouter.build(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BCC - Blessed Christian Church',
      debugShowCheckedModeBanner: false,
      theme: BCCTheme.lightTheme,
      darkTheme: BCCTheme.darkTheme,
      themeMode: context.watch<ThemeProvider>().themeMode,
      routerConfig: _router,
    );
  }
}
