import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            title: Text(auth.user?.name ?? 'User profile'),
            subtitle: Text('${auth.user?.email ?? ''} - ${auth.user?.role ?? ''}'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Cart alerts'),
            subtitle: const Text('Low battery, offline cart, sensor, and obstacle alerts'),
            value: settings.pushAlerts,
            onChanged: settings.setPushAlerts,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Appearance'),
            subtitle: const Text('Choose light, dark, or system mode'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (value) => settings.setThemeMode(value ?? ThemeMode.system),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('App display language'),
            trailing: DropdownButton<String>(
              value: settings.language,
              items: const ['English', 'Swahili'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: (value) => settings.setLanguage(value ?? 'English'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('SmartCart Manager'),
            subtitle: Text('Server connection is preconfigured for this cart system.'),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: auth.logout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}
