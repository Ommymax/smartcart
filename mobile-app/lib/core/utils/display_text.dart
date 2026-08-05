String readableStatus(String value) {
  final normalized = value.trim().toLowerCase();
  return switch (normalized) {
    '' => 'No update yet',
    'none' => 'Normal',
    'on' => 'On',
    'off' => 'Off',
    'moving_forward' => 'Moving forward',
    'turning_left' => 'Turning left',
    'turning_right' => 'Turning right',
    'stopped' => 'Stopped',
    'emergency_stop' => 'Emergency stop',
    'radio_not_connected' => 'Customer tag not connected',
    'customer_too_close' => 'Customer too close',
    'front_obstacle' => 'Obstacle ahead',
    'left_obstacle' => 'Obstacle on left',
    'right_obstacle' => 'Obstacle on right',
    'both_sides_blocked' => 'Path blocked',
    'front_sensor_inactive' => 'Front safety check unavailable',
    'left_path_unsafe' => 'Left side blocked',
    'right_path_unsafe' => 'Right side blocked',
    'app_remote' => 'Controlled from app',
    'app_stop' => 'Stopped from app',
    'app_emergency_stop' => 'Emergency stop from app',
    'auto_follow' => 'Following customer',
    'remote_timeout' => 'Remote control paused',
    'startup' => 'Starting',
    _ => value.replaceAll('_', ' ').split(' ').where((part) => part.isNotEmpty).map((part) {
        return part[0].toUpperCase() + part.substring(1);
      }).join(' '),
  };
}
