import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/display_text.dart';
import '../../shared/models/cart.dart';
import 'cart_control_screen.dart';
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
      body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartControlScreen(cart: cart))), icon: const Icon(Icons.gamepad), label: const Text('Control')),
                    FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveMonitoringScreen(cart: cart))), icon: const Icon(Icons.monitor_heart), label: const Text('Live')),
                    FilledButton.tonalIcon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartLocationScreen(cart: cart))), icon: const Icon(Icons.map), label: const Text('Location')),
                    FilledButton.tonalIcon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartHistoryScreen(cart: cart))), icon: const Icon(Icons.show_chart), label: const Text('History')),
                  ],
                ),
                const SizedBox(height: 16),
                if (telemetry == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No live update yet. Remote control will work when the cart is online.'),
                    ),
                  )
                else ...[
                _Section(
                  title: 'Cart status',
                  rows: {
                    'Cart ID': cart.cartId,
                    'Power': readableStatus(telemetry.powerStatus),
                    'Movement': readableStatus(telemetry.motionStatus),
                    'Current note': readableStatus(telemetry.stopReason),
                    'Battery level': '${telemetry.batteryPercentage}%',
                    'Cart link': telemetry.radioConnected ? 'Connected' : 'Not connected',
                    'Internet': telemetry.internetConnected ? 'Connected' : 'Not connected',
                    'Last update': telemetry.createdAt.toLocal().toString(),
                    'Working time': '${(telemetry.uptimeMs / 1000).round()} seconds',
                    'Left side signal': telemetry.leftRssi == null ? 'Unavailable' : '${telemetry.leftRssi}',
                    'Right side signal': telemetry.rightRssi == null ? 'Unavailable' : '${telemetry.rightRssi}',
                  },
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Safety distance',
                  rows: {
                    'Front check': telemetry.frontSensor.active ? 'OK' : 'Not available',
                    'Front distance': '${telemetry.frontSensor.distanceCm ?? 'Unavailable'} cm',
                    'Left check': telemetry.leftSensor.active ? 'OK' : 'Not available',
                    'Left distance': '${telemetry.leftSensor.distanceCm ?? 'Unavailable'} cm',
                    'Right check': telemetry.rightSensor.active ? 'OK' : 'Not available',
                    'Right distance': '${telemetry.rightSensor.distanceCm ?? 'Unavailable'} cm',
                  },
                ),
                ],
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
