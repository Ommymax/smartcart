import 'package:flutter/foundation.dart';
import '../../shared/models/alert_item.dart';
import '../../shared/services/api_service.dart';

class AlertProvider extends ChangeNotifier {
  AlertProvider(this.api);
  final ApiService api;

  List<AlertItem> alerts = [];
  bool loading = false;
  String? error;

  Future<void> loadAlerts() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await api.get('/api/alerts');
      alerts = (response['data'] as List).map((item) => AlertItem.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    await api.put('/api/alerts/$id/read', {});
    await loadAlerts();
  }

  Future<void> deleteAlert(String id) async {
    final previous = [...alerts];
    alerts = alerts.where((alert) => alert.id != id).toList();
    notifyListeners();
    try {
      await api.delete('/api/alerts/$id');
    } catch (e) {
      alerts = previous;
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearAlerts() async {
    final previous = [...alerts];
    final ids = previous.map((alert) => alert.id).where((id) => id.isNotEmpty).toList();
    alerts = [];
    notifyListeners();
    try {
      await api.delete('/api/alerts');
    } catch (e) {
      try {
        for (final id in ids) {
          await api.delete('/api/alerts/$id');
        }
      } catch (fallbackError) {
        alerts = previous;
        error = fallbackError.toString();
        notifyListeners();
        rethrow;
      }
    }
  }

  void prependSocketAlerts(List<dynamic> items) {
    alerts = [
      ...items.map((item) => AlertItem.fromJson(Map<String, dynamic>.from(item))),
      ...alerts,
    ];
    notifyListeners();
  }
}
