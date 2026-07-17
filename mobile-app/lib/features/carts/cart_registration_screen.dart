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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add smart cart')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Cart name'), validator: required),
            const SizedBox(height: 12),
            TextFormField(controller: id, decoration: const InputDecoration(labelText: 'Cart ID from ESP32, for example SMART_CART_001'), validator: required),
            const SizedBox(height: 12),
            TextFormField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextFormField(controller: assignedUserId, decoration: const InputDecoration(labelText: 'Assigned operator user ID')),
            const SizedBox(height: 12),
            TextFormField(controller: model, decoration: const InputDecoration(labelText: 'Model')),
            const SizedBox(height: 12),
            TextFormField(controller: serial, decoration: const InputDecoration(labelText: 'Serial number')),
            const SizedBox(height: 12),
            TextFormField(controller: installationDate, decoration: const InputDecoration(labelText: 'Installation date (YYYY-MM-DD)')),
            const SizedBox(height: 12),
            DropdownButtonFormField(initialValue: status, decoration: const InputDecoration(labelText: 'Status'), items: const [
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
            ], onChanged: (value) => setState(() => status = value ?? 'active')),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      final auth = context.read<AuthProvider>();
                      final body = {
                        'cartName': name.text,
                        'cartId': id.text,
                        'description': description.text,
                        'assignedUserId': assignedUserId.text.isEmpty ? null : assignedUserId.text,
                        'model': model.text,
                        'serialNumber': serial.text,
                        'installationDate': installationDate.text.isEmpty ? null : installationDate.text,
                        'status': status,
                      };
                      if (auth.userRole == 'administrator') {
                        await context.read<CartProvider>().createCart(body);
                      } else {
                        await context.read<CartProvider>().createMyCart(body);
                      }
                      if (mounted) Navigator.pop(context);
                    },
              icon: const Icon(Icons.save),
              label: const Text('Save smart cart'),
            ),
          ],
        ),
      ),
    );
  }

  String? required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
