import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../carts/cart_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carts = context.watch<CartProvider>();
    final telemetry = carts.latestTelemetry.values.toList();
    final avgBattery = telemetry.isEmpty ? 0 : telemetry.map((t) => t.batteryPercentage).reduce((a, b) => a + b) / telemetry.length;
    final avgUptime = telemetry.isEmpty ? 0 : telemetry.map((t) => t.uptimeMs).reduce((a, b) => a + b) / telemetry.length / 1000;
    final emergencyStops = telemetry.where((t) => t.motionStatus == 'emergency_stop').length;
    final obstacles = telemetry.where((t) => t.stopReason.toLowerCase().contains('obstacle')).length;
    final sensorFailures = telemetry.where((t) => !t.frontSensor.active || !t.leftSensor.active || !t.rightSensor.active).length;
    final moving = telemetry.where((t) => t.motionStatus.startsWith('moving')).length;
    final stopped = telemetry.length - moving;

    final rows = [
      ('Average battery usage', '${avgBattery.toStringAsFixed(1)}%', Icons.battery_std),
      ('Average uptime', '${avgUptime.toStringAsFixed(0)} seconds', Icons.timer),
      ('Emergency stops', '$emergencyStops', Icons.emergency),
      ('Obstacle detections', '$obstacles', Icons.report_problem),
      ('Sensor failure frequency', '$sensorFailures', Icons.sensors_off),
      ('Cart movement duration', '$moving samples', Icons.moving),
      ('Cart stopped duration', '$stopped samples', Icons.stop_circle),
      ('Most active carts', carts.carts.take(3).map((c) => c.cartName).join(', '), Icons.star),
    ];

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: MediaQuery.sizeOf(context).width > 900 ? 3 : 1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 4,
      children: rows.map((row) => Card(
            child: ListTile(
              leading: Icon(row.$3, color: Theme.of(context).colorScheme.primary),
              title: Text(row.$1),
              subtitle: Text(row.$2.isEmpty ? 'No telemetry yet' : row.$2),
            ),
          )).toList(),
    );
  }
}
