import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/state_views.dart';
import 'cart_detail_screen.dart';
import 'cart_provider.dart';
import 'cart_registration_screen.dart';

class CartListScreen extends StatefulWidget {
  const CartListScreen({super.key});

  @override
  State<CartListScreen> createState() => _CartListScreenState();
}

class _CartListScreenState extends State<CartListScreen> {
  String query = '';
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CartProvider>();
    if (provider.loading && provider.carts.isEmpty) return const LoadingView(message: 'Loading carts');
    if (provider.error != null) return ErrorStateView(message: provider.error!, onRetry: provider.loadCarts);

    final filtered = provider.carts.where((cart) {
      final t = provider.latestTelemetry[cart.cartId];
      final text = '${cart.cartName} ${cart.cartId}'.toLowerCase().contains(query.toLowerCase());
      final matches = switch (filter) {
        'Online' => cart.isOnline,
        'Offline' => !cart.isOnline,
        'Moving' => (t?.motionStatus ?? '').startsWith('moving'),
        'Stopped' => !(t?.motionStatus ?? '').startsWith('moving'),
        'Low battery' => (t?.batteryPercentage ?? 100) < 20,
        'Sensor failure' => t != null && (!t.frontSensor.active || !t.leftSensor.active || !t.rightSensor.active),
        _ => true,
      };
      return text && matches;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCart,
        icon: const Icon(Icons.add),
        label: const Text('Add cart'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search carts'),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 12),
                DropdownMenu<String>(
                  width: double.infinity,
                  initialSelection: filter,
                  onSelected: (value) => setState(() => filter = value ?? 'All'),
                  dropdownMenuEntries: const ['All', 'Online', 'Offline', 'Moving', 'Stopped', 'Low battery', 'Sensor failure']
                      .map((value) => DropdownMenuEntry(value: value, label: value))
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _NoCartView(onAdd: _openAddCart)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final cart = filtered[index];
                      final t = provider.latestTelemetry[cart.cartId];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: cart.isOnline ? Colors.green.shade100 : Colors.red.shade100,
                                  child: Icon(cart.isOnline ? Icons.wifi : Icons.wifi_off, color: cart.isOnline ? Colors.green : Colors.red),
                                ),
                                title: Text(cart.cartName, style: Theme.of(context).textTheme.titleMedium),
                                subtitle: Text('${cart.cartId} - ${t?.motionStatus ?? 'No telemetry yet'}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartDetailScreen(cart: cart))),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: _MiniStatus(label: 'Battery', value: t == null ? '--' : '${t.batteryPercentage}%')),
                                  Expanded(child: _MiniStatus(label: 'Radio', value: t?.radioConnected == true ? 'OK' : 'No data')),
                                  Expanded(child: _MiniStatus(label: 'GPS', value: t?.locationAvailable == true ? 'Ready' : 'No GPS')),
                                ],
                              ),
                              if (t != null) ...[
                                const SizedBox(height: 10),
                                LinearProgressIndicator(value: t.batteryPercentage / 100, minHeight: 8),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openAddCart() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartRegistrationScreen()));
  }
}

class _NoCartView extends StatelessWidget {
  const _NoCartView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_shopping_cart, size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text('No smart cart connected', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'Enter the Cart ID registered on the server. When the cart sends telemetry, battery, motion, sensor, and location data will appear here.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add smart cart')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  const _MiniStatus({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
