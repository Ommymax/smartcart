import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController apiUrl;

  @override
  void initState() {
    super.initState();
    apiUrl = TextEditingController(text: context.read<AuthProvider>().api.baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(auth.user?.name ?? 'User profile'),
            subtitle: Text('${auth.user?.email ?? ''} • ${auth.user?.role ?? ''}'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notification preferences'),
            subtitle: const Text('Receive active alert notifications'),
            value: settings.pushAlerts,
            onChanged: settings.setPushAlerts,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark and light mode'),
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
            title: const Text('Language selection'),
            trailing: DropdownButton<String>(
              value: settings.language,
              items: const ['English', 'Swahili'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: (value) => settings.setLanguage(value ?? 'English'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('API configuration', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(controller: apiUrl, decoration: const InputDecoration(labelText: 'Backend API base URL')),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => auth.saveApiBaseUrl(apiUrl.text.trim()),
                  icon: const Icon(Icons.save),
                  label: const Text('Save API URL'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.password),
            title: Text('Change password'),
            subtitle: Text('Use the backend reset-password endpoint in production.'),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: auth.logout, icon: const Icon(Icons.logout), label: const Text('Logout')),
      ],
    );
  }
}
