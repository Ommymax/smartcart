import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Loading'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _MovingDeviceLoader(),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _MovingDeviceLoader extends StatefulWidget {
  const _MovingDeviceLoader();

  @override
  State<_MovingDeviceLoader> createState() => _MovingDeviceLoaderState();
}

class _MovingDeviceLoaderState extends State<_MovingDeviceLoader> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 56,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final x = 16 + controller.value * 88;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: 8,
                right: 8,
                bottom: 10,
                child: Container(height: 3, color: Theme.of(context).colorScheme.outlineVariant),
              ),
              Positioned(
                left: x,
                bottom: 12,
                child: Icon(Icons.monitor_heart_outlined, size: 40, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, textAlign: TextAlign.center));
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 8),
          Text(_friendlyError(message), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

String _friendlyError(String message) {
  final text = message.toLowerCase();
  if (text.contains('401') || text.contains('invalid') || text.contains('token')) return 'Please sign in again.';
  if (text.contains('failed') || text.contains('socket') || text.contains('xmlhttprequest')) return 'Connection problem. Try again.';
  if (text.contains('route not found')) return 'This action is not available yet.';
  return 'Something went wrong. Try again.';
}
