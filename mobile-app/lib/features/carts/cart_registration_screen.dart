import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/services/socket_service.dart';
import '../settings/settings_provider.dart';
import 'cart_provider.dart';

class CartRegistrationScreen extends StatefulWidget {
  const CartRegistrationScreen({super.key});

  @override
  State<CartRegistrationScreen> createState() => _CartRegistrationScreenState();
}

class _CartRegistrationScreenState extends State<CartRegistrationScreen> {
  final formKey = GlobalKey<FormState>();
  final id = TextEditingController();
  final name = TextEditingController();
  bool saving = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<SettingsProvider>().text;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Add cart', 'Ongeza cart'))),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: id,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: tr('Cart ID', 'Namba ya cart'),
                hintText: tr('Enter Cart ID', 'Weka namba ya cart'),
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
              ),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: name,
              decoration: InputDecoration(
                labelText: tr('Cart name', 'Jina la cart'),
                hintText: tr('Example: Shopping cart', 'Mfano: Shopping cart'),
                prefixIcon: const Icon(Icons.shopping_cart_outlined),
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
              label: Text(tr('Add cart', 'Ongeza cart')),
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
      final cartId = id.text.trim();
      await context.read<CartProvider>().createMyCart({
        'cartId': cartId,
        'cartName': name.text.trim(),
      });
      if (mounted) context.read<SocketService>().joinCart(cartId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      final message = e.toString().contains('already') ? 'This cart is already added' : 'Unable to add cart';
      setState(() => error = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String? required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
