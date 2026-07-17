import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class RegisterSmartCartScreen extends StatefulWidget {
  const RegisterSmartCartScreen({super.key});

  @override
  State<RegisterSmartCartScreen> createState() => _RegisterSmartCartScreenState();
}

class _RegisterSmartCartScreenState extends State<RegisterSmartCartScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool obscure = true;
  bool obscureConfirm = true;
  String? error;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Create your account', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Full name'), validator: required),
                const SizedBox(height: 12),
                TextFormField(controller: email, decoration: const InputDecoration(labelText: 'Email'), validator: required),
                const SizedBox(height: 12),
                TextFormField(
                  controller: password,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: obscure ? 'Show password' : 'Hide password',
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 8) ? 'Use at least 8 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPassword,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      tooltip: obscureConfirm ? 'Show password' : 'Hide password',
                      icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  validator: (value) => value != password.text ? 'Passwords do not match' : null,
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                        onPressed: auth.loading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          try {
                            await auth.registerAccount(
                              name: name.text.trim(),
                              email: email.text.trim(),
                              password: password.text,
                            );
                            if (mounted) Navigator.of(context).pop();
                          } catch (e) {
                            setState(() => error = e.toString());
                          }
                        },
                  icon: auth.loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.app_registration),
                  label: const Text('Create account'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'After login, open Carts and add the ESP32 smart cart ID so the device telemetry can appear in the app.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
