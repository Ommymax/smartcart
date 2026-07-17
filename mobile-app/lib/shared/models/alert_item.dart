class AlertItem {
  AlertItem({
    required this.id,
    required this.cartId,
    required this.alertType,
    required this.message,
    required this.severity,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String cartId;
  final String alertType;
  final String message;
  final String severity;
  final bool isRead;
  final DateTime createdAt;

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] ?? '',
      cartId: json['cart_id'] ?? '',
      alertType: json['alert_type'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'info',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }
}
