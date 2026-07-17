import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/status_color.dart';
import '../../shared/widgets/state_views.dart';
import 'alert_provider.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();
    if (provider.loading && provider.alerts.isEmpty) return const LoadingView(message: 'Loading alerts');
    if (provider.error != null) return ErrorStateView(message: provider.error!, onRetry: provider.loadAlerts);
    if (provider.alerts.isEmpty) return const EmptyView(message: 'No alerts yet.');

    return RefreshIndicator(
      onRefresh: provider.loadAlerts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final alert = provider.alerts[index];
          return Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber, color: statusColor(context, alert.severity)),
              title: Text(alert.message),
              subtitle: Text('${alert.alertType} • ${alert.cartId} • ${alert.createdAt.toLocal()}'),
              trailing: alert.isRead
                  ? const Icon(Icons.done)
                  : IconButton(
                      tooltip: 'Mark read',
                      icon: const Icon(Icons.mark_email_read_outlined),
                      onPressed: () => provider.markRead(alert.id),
                    ),
            ),
          );
        },
      ),
    );
  }
}
