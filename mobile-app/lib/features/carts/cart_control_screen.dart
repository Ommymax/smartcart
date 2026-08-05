import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/display_text.dart';
import '../../shared/models/cart.dart';
import 'cart_provider.dart';

class CartControlScreen extends StatefulWidget {
  const CartControlScreen({super.key, required this.cart});
  final CartItem cart;

  @override
  State<CartControlScreen> createState() => _CartControlScreenState();
}

class _CartControlScreenState extends State<CartControlScreen> {
  Timer? _repeatTimer;
  double _speed = 90;
  String _lastCommand = 'Ready';
  bool _sending = false;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  Future<void> _send(String command, {int? speed, int durationMs = 700}) async {
    if (_sending && command != 'stop' && command != 'emergency_stop') return;
    setState(() {
      _sending = true;
      _lastCommand = command.replaceAll('_', ' ');
    });

    try {
      await context.read<CartProvider>().sendCommand(
            widget.cart.cartId,
            command: command,
            speed: speed ?? _speed.round(),
            durationMs: durationMs,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startHold(String command) {
    _repeatTimer?.cancel();
    _send(command, durationMs: 650);
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      _send(command, durationMs: 650);
    });
  }

  void _endHold() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _send('stop', speed: 0, durationMs: 500);
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<CartProvider>().latestTelemetry[widget.cart.cartId] ?? widget.cart.latestTelemetry;
    final online = telemetry != null && DateTime.now().difference(telemetry.createdAt).inMinutes < 2;

    return Scaffold(
      appBar: AppBar(title: Text('Control ${widget.cart.cartId}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(online ? Icons.wifi : Icons.wifi_off, color: online ? Colors.green : Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          online ? 'Cart online' : 'Waiting for cart to connect',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Last command: $_lastCommand'),
                  if (telemetry != null) ...[
                    const SizedBox(height: 6),
                    Text('Movement: ${readableStatus(telemetry.motionStatus)}'),
                    Text('Battery: ${telemetry.batteryPercentage}%'),
                    Text('Front distance: ${telemetry.frontSensor.distanceCm ?? '--'} cm'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Remote control', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Slow'),
                      Expanded(
                        child: Slider(
                          value: _speed,
                          min: 45,
                          max: 130,
                          divisions: 17,
                          label: _speed.round().toString(),
                          onChanged: (value) => setState(() => _speed = value),
                        ),
                      ),
                      const Text('Fast'),
                    ],
                  ),
                  Text('Cart speed', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  _HoldButton(
                    icon: Icons.keyboard_arrow_up,
                    label: 'Forward',
                    onHoldStart: () => _startHold('forward'),
                    onHoldEnd: _endHold,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _HoldButton(
                          icon: Icons.keyboard_arrow_left,
                          label: 'Left',
                          onHoldStart: () => _startHold('left'),
                          onHoldEnd: _endHold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _send('stop', speed: 0, durationMs: 900),
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HoldButton(
                          icon: Icons.keyboard_arrow_right,
                          label: 'Right',
                          onHoldStart: () => _startHold('right'),
                          onHoldEnd: _endHold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _send('auto', speed: 0, durationMs: 1000),
            icon: const Icon(Icons.sensors),
            label: const Text('Return to auto follow'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _send('emergency_stop', speed: 0, durationMs: 3000),
            icon: const Icon(Icons.warning_amber),
            label: const Text('Emergency stop'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.icon,
    required this.label,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final IconData icon;
  final String label;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onHoldStart(),
      onTapUp: (_) => onHoldEnd(),
      onTapCancel: onHoldEnd,
      onLongPressStart: (_) => onHoldStart(),
      onLongPressEnd: (_) => onHoldEnd(),
      child: FilledButton.icon(
        onPressed: null,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          disabledBackgroundColor: Theme.of(context).colorScheme.primary,
          disabledForegroundColor: Theme.of(context).colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(64),
        ),
      ),
    );
  }
}
