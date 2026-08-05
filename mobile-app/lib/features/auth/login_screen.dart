import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../settings/settings_provider.dart';
import 'auth_provider.dart';
import 'register_smart_cart_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;
  String? error;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final tr = settings.text;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.monitor_heart_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(AppConstants.appName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                TextField(controller: email, decoration: InputDecoration(labelText: tr('Email', 'Barua pepe'), prefixIcon: const Icon(Icons.email_outlined))),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: tr('Password', 'Nenosiri'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: obscure ? tr('Show password', 'Onyesha nenosiri') : tr('Hide password', 'Ficha nenosiri'),
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () {}, child: Text(tr('Forgot password?', 'Umesahau nenosiri?'))),
                ),
                if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: auth.loading
                      ? null
                      : () async {
                          try {
                            await auth.login(email.text.trim(), password.text);
                          } catch (e) {
                            final message = _loginMessage(e);
                            setState(() => error = message);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          }
                        },
                  icon: auth.loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
                  label: Text(auth.loading ? tr('Logging in', 'Inaingia') : tr('Login', 'Ingia')),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr("Don't have an account?", 'Huna akaunti?')),
                    TextButton(
                      onPressed: auth.loading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterSmartCartScreen()),
                              ),
                      child: Text(tr('Create account', 'Fungua akaunti')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _loginMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('invalid email') || text.contains('invalid') || text.contains('401')) {
      return 'Incorrect email or password';
    }
    return 'Unable to login. Try again.';
  }
}
