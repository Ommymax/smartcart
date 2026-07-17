import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/alerts/alert_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/carts/cart_provider.dart';
import 'features/settings/settings_provider.dart';
import 'shared/services/api_service.dart';
import 'shared/services/socket_service.dart';
import 'shared/widgets/app_scaffold.dart';
import 'shared/widgets/state_views.dart';

void main() {
  final api = ApiService(baseUrl: AppConfig.defaultApiBaseUrl);
  runApp(SmartCartApp(api: api));
}

class SmartCartApp extends StatelessWidget {
  const SmartCartApp({super.key, required this.api});
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api)..bootstrap()),
        ChangeNotifierProvider(create: (_) => CartProvider(api)),
        ChangeNotifierProvider(create: (_) => AlertProvider(api)),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        Provider(create: (_) => SocketService(socketUrl: AppConfig.defaultSocketUrl)),
      ],
      child: const SmartCartRoot(),
    );
  }
}

class SmartCartRoot extends StatefulWidget {
  const SmartCartRoot({super.key});

  @override
  State<SmartCartRoot> createState() => _SmartCartRootState();
}

class _SmartCartRootState extends State<SmartCartRoot> {
  bool socketStarted = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'SmartCart Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.loading) return const SplashScreen();
          if (!auth.isAuthenticated) return const LoginScreen();
          if (!socketStarted && auth.token != null) {
            socketStarted = true;
            final carts = context.read<CartProvider>();
            final alerts = context.read<AlertProvider>();
            context.read<SocketService>().connect(
                  auth.token!,
                  onTelemetry: carts.applyTelemetryPacket,
                  onAlerts: alerts.prependSocketAlerts,
                );
            Future.microtask(() {
              carts.loadCarts();
              alerts.loadAlerts();
            });
          }
          return const AppScaffold();
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('SmartCart Manager', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            const LoadingView(message: 'Checking backend and saved session'),
          ],
        ),
      ),
    );
  }
}
