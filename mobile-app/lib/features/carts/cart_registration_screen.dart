import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'cart_provider.dart';

class CartRegistrationScreen extends StatefulWidget {
  const CartRegistrationScreen({super.key});

  @override
  State<CartRegistrationScreen> createState() => _CartRegistrationScreenState();
}

class _CartRegistrationScreenState extends State<CartRegistrationScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final id = TextEditingController();
  final description = TextEditingController();
  final model = TextEditingController();
  final serial = TextEditingController();
  final installationDate = TextEditingController();
  final assignedUserId = TextEditingController();
  String status = 'active';
  bool saving = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().userRole == 'administrator';

    return Scaffold(
      appBar: AppBar(title: const Text('Add smart cart')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.memory, color: Theme.of(context).colorScheme.onSecondaryContainer),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Use the exact cartId configured in the ESP32 code. Telemetry will connect to this cart.'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: id, decoration: const InputDecoration(labelText: 'ESP32 cart ID', hintText: 'SMART_CART_001'), validator: required),
            const SizedBox(height: 12),
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Cart name', hintText: 'Entrance Cart 1'), validator: required),
            const SizedBox(height: 12),
            TextFormField(controller: model, decoration: const InputDecoration(labelText: 'Model')),
            const SizedBox(height: 12),
            TextFormField(controller: serial, decoration: const InputDecoration(labelText: 'Serial number')),
            const SizedBox(height: 12),
            TextFormField(controller: installationDate, decoration: const InputDecoration(labelText: 'Installation date (YYYY-MM-DD)')),
            const SizedBox(height: 12),
            TextFormField(controller: description, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              TextFormField(controller: assignedUserId, decoration: const InputDecoration(labelText: 'Assigned operator user ID')),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
                ],
                onChanged: (value) => setState(() => status = value ?? 'active'),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('Save smart cart'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final body = {
        'cartName': name.text.trim(),
        'cartId': id.text.trim(),
        'description': description.text.trim(),
        'assignedUserId': assignedUserId.text.trim().isEmpty ? null : assignedUserId.text.trim(),
        'model': model.text.trim(),
        'serialNumber': serial.text.trim(),
        'installationDate': installationDate.text.trim().isEmpty ? null : installationDate.text.trim(),
        'status': status,
      };
      if (auth.userRole == 'administrator') {
        await context.read<CartProvider>().createCart(body);
      } else {
        await context.read<CartProvider>().createMyCart(body);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String? required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
