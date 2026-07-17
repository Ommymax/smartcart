import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/state_views.dart';
import '../alerts/alert_provider.dart';
import '../carts/cart_registration_screen.dart';
import '../carts/cart_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carts = context.watch<CartProvider>();
    final alerts = context.watch<AlertProvider>();
    if (carts.loading && carts.carts.isEmpty) return const LoadingView(message: 'Loading dashboard');
    if (carts.error != null) return ErrorStateView(message: carts.error!, onRetry: carts.loadCarts);

    final all = carts.carts;
    final online = all.where((cart) => cart.isOnline).length;
    final moving = all.where((cart) => (carts.latestTelemetry[cart.cartId]?.motionStatus ?? '').startsWith('moving')).length;
    final lowBattery = all.where((cart) => (carts.latestTelemetry[cart.cartId]?.batteryPercentage ?? 100) < 20).length;
    final sensorErrors = all.where((cart) {
      final t = carts.latestTelemetry[cart.cartId];
      return t != null && (!t.frontSensor.active || !t.leftSensor.active || !t.rightSensor.active);
    }).length;

    final cards = [
      ('Total carts', all.length, Icons.shopping_cart),
      ('Online carts', online, Icons.wifi),
      ('Offline carts', all.length - online, Icons.wifi_off),
      ('Moving carts', moving, Icons.moving),
      ('Stopped carts', all.length - moving, Icons.stop_circle_outlined),
      ('Low battery', lowBattery, Icons.battery_alert),
      ('Sensor errors', sensorErrors, Icons.sensors_off),
      ('Active alerts', alerts.alerts.where((a) => !a.isRead).length, Icons.notifications_active),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        await carts.loadCarts();
        await alerts.loadAlerts();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connect smart cart', style: Theme.of(context).textTheme.titleMedium),
                        const Text('Add the cart ID registered on the server.'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartRegistrationScreen())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((item) => _SummaryCard(title: item.$1, value: item.$2, icon: item.$3)).toList(),
          ),
          const SizedBox(height: 20),
          Text('Recent cart activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...all.take(5).map((cart) => ListTile(
                leading: Icon(cart.isOnline ? Icons.check_circle : Icons.cancel, color: cart.isOnline ? Colors.green : Colors.red),
                title: Text(cart.cartName),
                subtitle: Text('${cart.cartId} - ${carts.latestTelemetry[cart.cartId]?.motionStatus ?? 'No telemetry'}'),
                trailing: Text('${carts.latestTelemetry[cart.cartId]?.batteryPercentage ?? 0}%'),
              )),
          const SizedBox(height: 20),
          Text('Latest alerts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...alerts.alerts.take(5).map((alert) => ListTile(
                leading: const Icon(Icons.warning_amber),
                title: Text(alert.message),
                subtitle: Text('${alert.cartId} - ${alert.severity}'),
              )),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value, required this.icon});
  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width < 520 ? double.infinity : 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('$value', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
