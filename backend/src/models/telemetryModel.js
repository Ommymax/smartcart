const db = require('../config/db');

async function insertTelemetry(payload) {
  const result = await db.query(
    `INSERT INTO telemetry (
      cart_id, power_status, motion_status, stop_reason, battery_voltage, battery_percentage,
      radio_connected, internet_connected, front_sensor_active, front_distance_cm,
      left_sensor_active, left_distance_cm, right_sensor_active, right_distance_cm,
      left_rssi, right_rssi, latitude, longitude, location_available, uptime_ms
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)
    RETURNING *`,
    [
      payload.cartId,
      payload.powerStatus,
      payload.motionStatus,
      payload.stopReason,
      payload.batteryVoltage,
      payload.batteryPercentage,
      payload.radioConnected,
      payload.internetConnected,
      payload.ultrasonic.front.active,
      payload.ultrasonic.front.distanceCm,
      payload.ultrasonic.left.active,
      payload.ultrasonic.left.distanceCm,
      payload.ultrasonic.right.active,
      payload.ultrasonic.right.distanceCm,
      payload.rssi.left,
      payload.rssi.right,
      payload.location.latitude,
      payload.location.longitude,
      payload.location.available,
      payload.uptimeMs
    ]
  );
  await db.query('UPDATE carts SET updated_at = NOW() WHERE cart_id = $1', [payload.cartId]);
  return result.rows[0];
}

async function latestTelemetry(cartId) {
  const result = await db.query(
    'SELECT * FROM telemetry WHERE cart_id = $1 ORDER BY created_at DESC LIMIT 1',
    [cartId]
  );
  return result.rows[0];
}

async function telemetryHistory(cartId, { from, to, limit = 500 }) {
  const params = [cartId];
  const clauses = ['cart_id = $1'];
  if (from) {
    params.push(from);
    clauses.push(`created_at >= $${params.length}`);
  }
  if (to) {
    params.push(to);
    clauses.push(`created_at <= $${params.length}`);
  }
  params.push(Math.min(Number(limit) || 500, 2000));
  const result = await db.query(
    `SELECT * FROM telemetry WHERE ${clauses.join(' AND ')}
     ORDER BY created_at DESC LIMIT $${params.length}`,
    params
  );
  return result.rows;
}

async function staleCarts(seconds = 30) {
  const result = await db.query(
    `SELECT c.cart_id, c.cart_name, MAX(t.created_at) AS last_telemetry_at
     FROM carts c
     LEFT JOIN telemetry t ON t.cart_id = c.cart_id
     WHERE c.status = 'active'
     GROUP BY c.cart_id, c.cart_name
     HAVING MAX(t.created_at) IS NULL OR MAX(t.created_at) < NOW() - ($1 || ' seconds')::interval`,
    [seconds]
  );
  return result.rows;
}

module.exports = {
  insertTelemetry,
  latestTelemetry,
  telemetryHistory,
  staleCarts
};
