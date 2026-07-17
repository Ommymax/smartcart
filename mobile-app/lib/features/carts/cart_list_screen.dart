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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search carts'),
                  onChanged: (value) => setState(() => query = value),
                ),
              ),
              DropdownMenu<String>(
                initialSelection: filter,
                onSelected: (value) => setState(() => filter = value ?? 'All'),
                dropdownMenuEntries: const ['All', 'Online', 'Offline', 'Moving', 'Stopped', 'Low battery', 'Sensor failure']
                    .map((value) => DropdownMenuEntry(value: value, label: value))
                    .toList(),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartRegistrationScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Add smart cart'),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyView(message: 'No carts yet. Use Add smart cart to enter the ESP32 cart ID and details.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cart = filtered[index];
                    final t = provider.latestTelemetry[cart.cartId];
                    return Card(
                      child: ListTile(
                        leading: Icon(cart.isOnline ? Icons.wifi : Icons.wifi_off, color: cart.isOnline ? Colors.green : Colors.red),
                        title: Text(cart.cartName),
                        subtitle: Text('${cart.cartId} • ${t?.motionStatus ?? 'No telemetry'} • sensors ${t == null ? 'unavailable' : 'health checked'}'),
                        trailing: t == null
                            ? const Text('No data')
                            : SizedBox(
                                width: 90,
                                child: LinearProgressIndicator(value: t.batteryPercentage / 100, minHeight: 8),
                              ),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartDetailScreen(cart: cart))),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
