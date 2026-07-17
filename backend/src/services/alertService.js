const alertModel = require('../models/alertModel');

function buildTelemetryAlerts(payload) {
  const alerts = [];
  const cartId = payload.cartId;
  const stopReason = (payload.stopReason || '').toLowerCase();

  if (payload.batteryPercentage < 10) {
    alerts.push({
      cartId,
      alertType: 'battery_critical',
      message: `${cartId} battery is critically low (${payload.batteryPercentage}%).`,
      severity: 'critical'
    });
  } else if (payload.batteryPercentage < 20) {
    alerts.push({
      cartId,
      alertType: 'low_battery',
      message: `${cartId} battery is low (${payload.batteryPercentage}%).`,
      severity: 'warning'
    });
  }

  if (!payload.radioConnected) {
    alerts.push({ cartId, alertType: 'radio_disconnected', message: `${cartId} radio link is disconnected.`, severity: 'critical' });
  }
  if (!payload.internetConnected) {
    alerts.push({ cartId, alertType: 'internet_disconnected', message: `${cartId} internet connection is disconnected.`, severity: 'critical' });
  }
  if (!payload.ultrasonic.front.active) {
    alerts.push({ cartId, alertType: 'front_sensor_inactive', message: `${cartId} front ultrasonic sensor is inactive.`, severity: 'warning' });
  }
  if (!payload.ultrasonic.left.active) {
    alerts.push({ cartId, alertType: 'left_sensor_inactive', message: `${cartId} left ultrasonic sensor is inactive.`, severity: 'warning' });
  }
  if (!payload.ultrasonic.right.active) {
    alerts.push({ cartId, alertType: 'right_sensor_inactive', message: `${cartId} right ultrasonic sensor is inactive.`, severity: 'warning' });
  }
  if (payload.motionStatus === 'emergency_stop') {
    alerts.push({ cartId, alertType: 'emergency_stop', message: `${cartId} entered emergency stop.`, severity: 'critical' });
  }
  if (stopReason === 'customer_too_close') {
    alerts.push({ cartId, alertType: 'customer_too_close', message: `${cartId} stopped because customer is too close.`, severity: 'warning' });
  }
  if (stopReason.includes('obstacle')) {
    alerts.push({ cartId, alertType: 'obstacle_detected', message: `${cartId} detected an obstacle.`, severity: 'warning' });
  }

  return alerts;
}

async function createTelemetryAlerts(payload) {
  const created = [];
  for (const alert of buildTelemetryAlerts(payload)) {
    const saved = await alertModel.createAlert(alert);
    if (saved) created.push(saved);
  }
  return created;
}

async function createOfflineAlert(cart) {
  return alertModel.createAlert({
    cartId: cart.cart_id,
    alertType: 'cart_offline',
    message: `${cart.cart_name || cart.cart_id} has not sent telemetry for more than 30 seconds.`,
    severity: 'critical'
  });
}

module.exports = {
  createTelemetryAlerts,
  createOfflineAlert
};
