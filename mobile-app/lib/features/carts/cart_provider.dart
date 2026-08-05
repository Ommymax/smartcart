import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../shared/models/cart.dart';
import '../../shared/models/telemetry.dart';
import '../../shared/services/api_service.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this.api);
  final ApiService api;
  static const _autoRefreshInterval = Duration(seconds: 10);
  static const _onlineWindow = Duration(minutes: 2);

  List<CartItem> carts = [];
  final Map<String, Telemetry> latestTelemetry = {};
  Timer? _refreshTimer;
  bool loading = false;
  String? error;

  bool isOnline(CartItem cart) {
    final last = (latestTelemetry[cart.cartId] ?? cart.latestTelemetry)?.createdAt;
    return last != null && DateTime.now().difference(last) <= _onlineWindow;
  }

  void startAutoRefresh() {
    _refreshTimer ??= Timer.periodic(_autoRefreshInterval, (_) => loadCarts(silent: true));
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> loadCarts({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
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

  Future<void> sendCommand(String cartId, {required String command, int speed = 90, int durationMs = 700}) async {
    await api.post('/api/carts/$cartId/command', {
      'command': command,
      'speed': speed,
      'durationMs': durationMs,
    });
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

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
