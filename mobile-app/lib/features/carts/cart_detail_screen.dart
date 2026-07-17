import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/models/cart.dart';
import 'cart_history_screen.dart';
import 'cart_location_screen.dart';
import 'cart_provider.dart';
import 'live_monitoring_screen.dart';

class CartDetailScreen extends StatelessWidget {
  const CartDetailScreen({super.key, required this.cart});
  final CartItem cart;

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<CartProvider>().latestTelemetry[cart.cartId] ?? cart.latestTelemetry;
    return Scaffold(
      appBar: AppBar(title: Text(cart.cartName)),
      body: telemetry == null
          ? const Center(child: Text('No telemetry has been received for this cart.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveMonitoringScreen(cart: cart))), icon: const Icon(Icons.monitor_heart), label: const Text('Live')),
                    FilledButton.tonalIcon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartLocationScreen(cart: cart))), icon: const Icon(Icons.map), label: const Text('Location')),
                    FilledButton.tonalIcon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartHistoryScreen(cart: cart))), icon: const Icon(Icons.show_chart), label: const Text('History')),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Cart status',
                  rows: {
                    'Cart ID': cart.cartId,
                    'Power status': telemetry.powerStatus,
                    'Motion status': telemetry.motionStatus,
                    'Stop reason': telemetry.stopReason,
                    'Battery voltage': '${telemetry.batteryVoltage} V',
                    'Battery percentage': '${telemetry.batteryPercentage}%',
                    'Radio connection': telemetry.radioConnected ? 'Connected' : 'Disconnected',
                    'Internet connection': telemetry.internetConnected ? 'Connected' : 'Disconnected',
                    'Last telemetry time': telemetry.createdAt.toLocal().toString(),
                    'Uptime': '${(telemetry.uptimeMs / 1000).round()} seconds',
                    'Left RSSI': '${telemetry.leftRssi ?? 'Unavailable'}',
                    'Right RSSI': '${telemetry.rightRssi ?? 'Unavailable'}',
                  },
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Ultrasonic sensors',
                  rows: {
                    'Front sensor': telemetry.frontSensor.active ? 'Active' : 'Inactive',
                    'Front distance': '${telemetry.frontSensor.distanceCm ?? 'Unavailable'} cm',
                    'Left sensor': telemetry.leftSensor.active ? 'Active' : 'Inactive',
                    'Left distance': '${telemetry.leftSensor.distanceCm ?? 'Unavailable'} cm',
                    'Right sensor': telemetry.rightSensor.active ? 'Active' : 'Inactive',
                    'Right distance': '${telemetry.rightSensor.distanceCm ?? 'Unavailable'} cm',
                  },
                ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...rows.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Flexible(child: Text(entry.value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
