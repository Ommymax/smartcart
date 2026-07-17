class SensorReading {
  SensorReading({required this.active, this.distanceCm});
  final bool active;
  final num? distanceCm;
}

class Telemetry {
  Telemetry({
    required this.cartId,
    required this.powerStatus,
    required this.motionStatus,
    required this.stopReason,
    required this.batteryVoltage,
    required this.batteryPercentage,
    required this.radioConnected,
    required this.internetConnected,
    required this.frontSensor,
    required this.leftSensor,
    required this.rightSensor,
    this.leftRssi,
    this.rightRssi,
    required this.locationAvailable,
    this.latitude,
    this.longitude,
    required this.uptimeMs,
    required this.createdAt,
  });

  final String cartId;
  final String powerStatus;
  final String motionStatus;
  final String stopReason;
  final num batteryVoltage;
  final int batteryPercentage;
  final bool radioConnected;
  final bool internetConnected;
  final SensorReading frontSensor;
  final SensorReading leftSensor;
  final SensorReading rightSensor;
  final int? leftRssi;
  final int? rightRssi;
  final bool locationAvailable;
  final num? latitude;
  final num? longitude;
  final int uptimeMs;
  final DateTime createdAt;

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      cartId: json['cart_id'] ?? json['cartId'] ?? '',
      powerStatus: json['power_status'] ?? json['powerStatus'] ?? 'unavailable',
      motionStatus: json['motion_status'] ?? json['motionStatus'] ?? 'unavailable',
      stopReason: json['stop_reason'] ?? json['stopReason'] ?? 'none',
      batteryVoltage: num.tryParse('${json['battery_voltage'] ?? json['batteryVoltage'] ?? 0}') ?? 0,
      batteryPercentage: int.tryParse('${json['battery_percentage'] ?? json['batteryPercentage'] ?? 0}') ?? 0,
      radioConnected: json['radio_connected'] ?? json['radioConnected'] ?? false,
      internetConnected: json['internet_connected'] ?? json['internetConnected'] ?? false,
      frontSensor: SensorReading(
        active: json['front_sensor_active'] ?? false,
        distanceCm: num.tryParse('${json['front_distance_cm'] ?? ''}'),
      ),
      leftSensor: SensorReading(
        active: json['left_sensor_active'] ?? false,
        distanceCm: num.tryParse('${json['left_distance_cm'] ?? ''}'),
      ),
      rightSensor: SensorReading(
        active: json['right_sensor_active'] ?? false,
        distanceCm: num.tryParse('${json['right_distance_cm'] ?? ''}'),
      ),
      leftRssi: int.tryParse('${json['left_rssi'] ?? ''}'),
      rightRssi: int.tryParse('${json['right_rssi'] ?? ''}'),
      locationAvailable: json['location_available'] ?? false,
      latitude: num.tryParse('${json['latitude'] ?? ''}'),
      longitude: num.tryParse('${json['longitude'] ?? ''}'),
      uptimeMs: int.tryParse('${json['uptime_ms'] ?? json['uptimeMs'] ?? 0}') ?? 0,
      createdAt: DateTime.tryParse('${json['created_at'] ?? DateTime.now().toIso8601String()}') ?? DateTime.now(),
    );
  }
}
