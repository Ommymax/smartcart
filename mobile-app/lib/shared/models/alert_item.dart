class AlertItem {
  AlertItem({
    required this.id,
    required this.cartId,
    this.cartName,
    required this.alertType,
    required this.message,
    required this.severity,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String cartId;
  final String? cartName;
  final String alertType;
  final String message;
  final String severity;
  final bool isRead;
  final DateTime createdAt;

  String get title {
    return switch (alertType) {
      'battery_critical' => 'Battery critical',
      'low_battery' => 'Low battery',
      'radio_disconnected' => 'Cart link lost',
      'internet_disconnected' => 'Internet not connected',
      'front_sensor_inactive' => 'Front safety check issue',
      'left_sensor_inactive' => 'Left safety check issue',
      'right_sensor_inactive' => 'Right safety check issue',
      'emergency_stop' => 'Emergency stop',
      'customer_too_close' => 'Customer too close',
      'obstacle_detected' => 'Obstacle detected',
      'offline' || 'cart_offline' => 'Cart offline',
      _ => alertType
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join(' '),
    };
  }

  String get displayMessage {
    if (message.isEmpty) return title;
    return message
        .replaceAll(RegExp('telemetry', caseSensitive: false), 'update')
        .replaceAll(RegExp('device link', caseSensitive: false), 'cart link')
        .replaceAll(RegExp('ultrasonic sensor', caseSensitive: false), 'safety check')
        .replaceAll(RegExp('sensor', caseSensitive: false), 'safety check');
  }

  String get displaySeverity {
    return switch (severity.toLowerCase()) {
      'critical' => 'Urgent',
      'warning' => 'Warning',
      'info' => 'Info',
      _ => severity,
    };
  }

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] ?? '',
      cartId: json['cart_id'] ?? '',
      cartName: json['cart_name'],
      alertType: json['alert_type'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'info',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }
}
