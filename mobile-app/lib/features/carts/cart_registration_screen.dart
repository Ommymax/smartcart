import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

class CartRegistrationScreen extends StatefulWidget {
  const CartRegistrationScreen({super.key});

  @override
  State<CartRegistrationScreen> createState() => _CartRegistrationScreenState();
}

class _CartRegistrationScreenState extends State<CartRegistrationScreen> {
  final formKey = GlobalKey<FormState>();
  final id = TextEditingController();
  bool saving = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add smart cart')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Enter the Cart ID registered on the server. It must match the cart device ID.'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: id,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Cart ID',
                hintText: 'SMART_CART_001',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              validator: required,
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_link),
              label: const Text('Add cart'),
            ),
            const SizedBox(height: 12),
            const Text(
              'The date is saved automatically when the cart is added.',
              textAlign: TextAlign.center,
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
      await context.read<CartProvider>().createMyCart({'cartId': id.text.trim()});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      final message = e.toString().contains('ID not found') ? 'ID not found' : e.toString();
      setState(() => error = message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String? required(String? value) => value == null || value.trim().isEmpty ? 'Cart ID is required' : null;
}
