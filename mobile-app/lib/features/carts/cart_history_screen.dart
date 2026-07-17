import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../shared/models/cart.dart';
import '../../shared/models/telemetry.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

class CartHistoryScreen extends StatefulWidget {
  const CartHistoryScreen({super.key, required this.cart});
  final CartItem cart;

  @override
  State<CartHistoryScreen> createState() => _CartHistoryScreenState();
}

class _CartHistoryScreenState extends State<CartHistoryScreen> {
  String range = '7d';
  late Future<List<Telemetry>> future;

  @override
  void initState() {
    super.initState();
    future = context.read<CartProvider>().history(widget.cart.cartId, range: range);
  }

  void reload(String value) {
    setState(() {
      range = value;
      future = context.read<CartProvider>().history(widget.cart.cartId, range: range);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('History ${widget.cart.cartId}')),
      body: FutureBuilder<List<Telemetry>>(
        future: future,
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'today', label: Text('Today')),
                  ButtonSegment(value: '7d', label: Text('Last 7 days')),
                  ButtonSegment(value: '30d', label: Text('Last 30 days')),
                ],
                selected: {range},
                onSelectionChanged: (value) => reload(value.first),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting) const LinearProgressIndicator(),
              if (data.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No telemetry history for this period.'))),
              if (data.isNotEmpty) ...[
                _Chart(title: 'Battery percentage', values: data.map((t) => t.batteryPercentage.toDouble()).toList()),
                _Chart(title: 'Battery voltage', values: data.map((t) => t.batteryVoltage.toDouble()).toList()),
                _Chart(title: 'RSSI left/right average', values: data.map((t) => (((t.leftRssi ?? 0) + (t.rightRssi ?? 0)) / 2).toDouble()).toList()),
                _Chart(title: 'Distance average', values: data.map((t) => (((t.frontSensor.distanceCm ?? 0) + (t.leftSensor.distanceCm ?? 0) + (t.rightSensor.distanceCm ?? 0)) / 3).toDouble()).toList()),
                Text('Motion timeline', style: Theme.of(context).textTheme.titleLarge),
                ...data.take(30).map((t) => ListTile(title: Text(t.motionStatus), subtitle: Text('${t.stopReason} • ${t.createdAt.toLocal()}'))),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.title, required this.values});
  final String title;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Expanded(
                child: LineChart(LineChartData(
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
                      isCurved: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
