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

  void prependSocketAlerts(List<dynamic> items) {
    alerts = [
      ...items.map((item) => AlertItem.fromJson(Map<String, dynamic>.from(item))),
      ...alerts,
    ];
    notifyListeners();
  }
}
