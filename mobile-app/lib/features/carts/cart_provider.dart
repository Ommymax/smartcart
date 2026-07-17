import 'package:flutter/foundation.dart';
import '../../shared/models/cart.dart';
import '../../shared/models/telemetry.dart';
import '../../shared/services/api_service.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this.api);
  final ApiService api;

  List<CartItem> carts = [];
  final Map<String, Telemetry> latestTelemetry = {};
  bool loading = false;
  String? error;

  Future<void> loadCarts() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await api.get('/api/carts');
      carts = (response['data'] as List).map((item) => CartItem.fromJson(Map<String, dynamic>.from(item))).toList();
      for (final cart in carts) {
        final telemetry = cart.latestTelemetry;
        if (telemetry != null) latestTelemetry[cart.cartId] = telemetry;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createCart(Map<String, dynamic> body) async {
    await api.post('/api/carts', body);
    await loadCarts();
  }

  Future<void> createMyCart(Map<String, dynamic> body) async {
    await api.post('/api/carts/mine', body);
    await loadCarts();
  }

  Future<List<Telemetry>> history(String cartId, {String range = '7d'}) async {
    final now = DateTime.now();
    final from = switch (range) {
      'today' => DateTime(now.year, now.month, now.day),
      '30d' => now.subtract(const Duration(days: 30)),
      _ => now.subtract(const Duration(days: 7)),
    };
    final response = await api.get('/api/carts/$cartId/telemetry/history?from=${from.toIso8601String()}');
    return (response['data'] as List).map((item) => Telemetry.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  void applyTelemetryPacket(Map<String, dynamic> packet) {
    final telemetryJson = Map<String, dynamic>.from(packet['telemetry']);
    final telemetry = Telemetry.fromJson(telemetryJson);
    latestTelemetry[telemetry.cartId] = telemetry;
    notifyListeners();
  }
}
