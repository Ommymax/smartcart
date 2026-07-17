import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/models/cart.dart';
import 'cart_provider.dart';

class LiveMonitoringScreen extends StatelessWidget {
  const LiveMonitoringScreen({super.key, required this.cart});
  final CartItem cart;

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<CartProvider>().latestTelemetry[cart.cartId] ?? cart.latestTelemetry;
    return Scaffold(
      appBar: AppBar(title: Text('Live ${cart.cartId}')),
      body: telemetry == null
          ? const Center(child: Text('Waiting for the first telemetry packet.'))
          : GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 1,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3.4,
              children: [
                _LiveTile('Motion', telemetry.motionStatus, Icons.moving),
                _LiveTile('Battery', '${telemetry.batteryPercentage}%', Icons.battery_charging_full),
                _LiveTile('Front sensor', '${telemetry.frontSensor.distanceCm ?? '--'} cm', Icons.sensors),
                _LiveTile('Left RSSI', '${telemetry.leftRssi ?? '--'} dBm', Icons.network_check),
                _LiveTile('Right RSSI', '${telemetry.rightRssi ?? '--'} dBm', Icons.network_check),
                _LiveTile('Connection', telemetry.internetConnected ? 'Online' : 'Disconnected', Icons.wifi),
                _LiveTile('Last packet', telemetry.createdAt.toLocal().toString(), Icons.schedule),
              ],
            ),
    );
  }
}

class _LiveTile extends StatelessWidget {
  const _LiveTile(this.title, this.value, this.icon);
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title),
                  Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
