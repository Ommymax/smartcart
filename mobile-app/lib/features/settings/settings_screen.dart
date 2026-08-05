import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../auth/auth_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final tr = settings.text;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(tr('Settings', 'Mipangilio'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            title: Text(auth.user?.name ?? tr('User profile', 'Taarifa za mtumiaji')),
            subtitle: Text(auth.user?.email ?? AppConstants.appName),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(tr('Cart alerts', 'Tahadhari za cart')),
            subtitle: Text(tr('Battery, connection, safety, and obstacle alerts', 'Chaji, connection, usalama na vizuizi')),
            value: settings.pushAlerts,
            onChanged: settings.setPushAlerts,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(tr('Theme', 'Muonekano')),
            subtitle: Text(tr('Choose app appearance', 'Chagua muonekano wa app')),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(tr('System', 'Mfumo'))),
                DropdownMenuItem(value: ThemeMode.light, child: Text(tr('Light', 'Mwanga'))),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(tr('Dark', 'Giza'))),
              ],
              onChanged: (value) => settings.setThemeMode(value ?? ThemeMode.system),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text(tr('Language', 'Lugha')),
            subtitle: Text(tr('Choose app language', 'Chagua lugha ya app')),
            trailing: DropdownButton<String>(
              value: settings.language,
              items: const ['English', 'Swahili'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: (value) => settings.setLanguage(value ?? 'English'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(AppConstants.appName),
            subtitle: Text(tr('Connected', 'Imeunganishwa')),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: auth.logout,
          icon: const Icon(Icons.logout),
          label: Text(tr('Logout', 'Toka')),
        ),
      ],
    );
  }
}
