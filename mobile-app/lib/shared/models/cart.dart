import 'telemetry.dart';

class CartItem {
  CartItem({
    required this.cartId,
    required this.cartName,
    this.description,
    this.serialNumber,
    this.model,
    this.installationDate,
    required this.status,
    this.assignedUserName,
    this.latestTelemetry,
  });

  final String cartId;
  final String cartName;
  final String? description;
  final String? serialNumber;
  final String? model;
  final String? installationDate;
  final String status;
  final String? assignedUserName;
  final Telemetry? latestTelemetry;

  bool get isOnline {
    final last = latestTelemetry?.createdAt;
    return last != null && DateTime.now().difference(last).inSeconds <= 30;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final hasTelemetry = json['last_telemetry_at'] != null || json['battery_percentage'] != null;
    return CartItem(
      cartId: json['cart_id'] ?? json['cartId'] ?? '',
      cartName: json['cart_name'] ?? json['cartName'] ?? '',
      description: json['description'],
      serialNumber: json['serial_number'],
      model: json['model'],
      installationDate: json['installation_date'],
      status: json['status'] ?? 'active',
      assignedUserName: json['assigned_user_name'],
      latestTelemetry: hasTelemetry
          ? Telemetry.fromJson({
              ...json,
              'created_at': json['last_telemetry_at'],
            })
          : null,
    );
  }
}
