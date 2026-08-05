import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/status_color.dart';
import '../../shared/widgets/state_views.dart';
import '../carts/cart_provider.dart';
import 'alert_provider.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();
    final carts = context.watch<CartProvider>();
    if (provider.loading && provider.alerts.isEmpty) return const LoadingView(message: 'Loading alerts');
    if (provider.error != null) return ErrorStateView(message: provider.error!, onRetry: provider.loadAlerts);
    if (provider.alerts.isEmpty) return const EmptyView(message: 'No alerts');

    return RefreshIndicator(
      onRefresh: provider.loadAlerts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.alerts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Row(
              children: [
                Text('Alerts', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await provider.clearAlerts();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unable to clear alerts')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear all'),
                ),
              ],
            );
          }
          final alert = provider.alerts[index - 1];
          final cartName = alert.cartName ?? _cartNameFor(carts, alert.cartId);
          return Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber, color: statusColor(context, alert.severity)),
              title: Text(alert.title),
              subtitle: Text('${alert.displayMessage}\n$cartName - ${alert.displaySeverity}'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  if (!alert.isRead)
                    IconButton(
                      tooltip: 'Mark read',
                      icon: const Icon(Icons.mark_email_read_outlined),
                      onPressed: () => provider.markRead(alert.id),
                    ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      try {
                        await provider.deleteAlert(alert.id);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unable to delete alert')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _cartNameFor(CartProvider carts, String cartId) {
    for (final cart in carts.carts) {
      if (cart.cartId == cartId) return cart.cartName;
    }
    return cartId;
  }
}
