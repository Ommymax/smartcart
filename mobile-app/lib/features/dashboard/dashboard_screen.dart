import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/display_text.dart';
import '../../shared/widgets/state_views.dart';
import '../alerts/alert_provider.dart';
import '../carts/cart_registration_screen.dart';
import '../carts/cart_provider.dart';
import '../settings/settings_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carts = context.watch<CartProvider>();
    final alerts = context.watch<AlertProvider>();
    final tr = context.watch<SettingsProvider>().text;
    if (carts.loading && carts.carts.isEmpty) return LoadingView(message: tr('Loading your carts', 'Inapakia cart zako'));
    if (carts.error != null) return ErrorStateView(message: carts.error!, onRetry: carts.loadCarts);

    final all = carts.carts;
    final online = all.where(carts.isOnline).length;
    final moving = all.where((cart) => (carts.latestTelemetry[cart.cartId]?.motionStatus ?? '').startsWith('moving')).length;
    final lowBattery = all.where((cart) => (carts.latestTelemetry[cart.cartId]?.batteryPercentage ?? 100) < 20).length;
    final sensorErrors = all.where((cart) {
      final t = carts.latestTelemetry[cart.cartId];
      return t != null && (!t.frontSensor.active || !t.leftSensor.active || !t.rightSensor.active);
    }).length;

    final cards = [
      (tr('Total carts', 'Cart zote'), all.length, Icons.shopping_cart),
      (tr('Online', 'Ipo hewani'), online, Icons.wifi),
      (tr('Offline', 'Haipo hewani'), all.length - online, Icons.wifi_off),
      (tr('Moving', 'Inatembea'), moving, Icons.moving),
      (tr('Stopped', 'Imesimama'), all.length - moving, Icons.stop_circle_outlined),
      (tr('Low battery', 'Chaji ndogo'), lowBattery, Icons.battery_alert),
      (tr('Safety issues', 'Tahadhari za usalama'), sensorErrors, Icons.sensors_off),
      (tr('Alerts', 'Tahadhari'), alerts.alerts.where((a) => !a.isRead).length, Icons.notifications_active),
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
                  Icon(Icons.add_to_queue, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('My carts', 'Cart zangu'), style: Theme.of(context).textTheme.titleMedium),
                        Text(tr('Add and monitor your smart cart.', 'Ongeza na fuatilia smart cart yako.')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartRegistrationScreen())),
                    icon: const Icon(Icons.add),
                    label: Text(tr('Add', 'Ongeza')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.28,
            children: cards.map((item) => _SummaryCard(title: item.$1, value: item.$2, icon: item.$3)).toList(),
          ),
          const SizedBox(height: 20),
          Text(tr('Recent activity', 'Taarifa za karibuni'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...all.take(5).map((cart) {
            final telemetry = carts.latestTelemetry[cart.cartId];
            final batteryPercentage = telemetry?.batteryPercentage;
            final online = carts.isOnline(cart);
            return Card(
              child: ListTile(
                leading: Icon(online ? Icons.check_circle : Icons.cancel, color: online ? Colors.green : Colors.red),
                title: Text(cart.cartName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${cart.cartId} - ${telemetry == null ? 'No update yet' : readableStatus(telemetry.motionStatus)}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.battery_std, size: 18),
                        const SizedBox(width: 6),
                        Text(batteryPercentage == null ? 'Battery: --' : 'Battery: $batteryPercentage%'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: batteryPercentage == null ? 0 : batteryPercentage / 100,
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Text(tr('Latest alerts', 'Tahadhari za karibuni'), style: Theme.of(context).textTheme.titleLarge),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text('$value', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 2),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
