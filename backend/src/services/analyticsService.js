const db = require('../config/db');

async function summary() {
  const result = await db.query(
    `WITH latest AS (
      SELECT DISTINCT ON (cart_id) * FROM telemetry ORDER BY cart_id, created_at DESC
    )
    SELECT
      (SELECT COUNT(*)::int FROM carts) AS total_carts,
      COUNT(*) FILTER (WHERE latest.created_at > NOW() - INTERVAL '30 seconds')::int AS online_carts,
      COUNT(*) FILTER (WHERE latest.created_at IS NULL OR latest.created_at <= NOW() - INTERVAL '30 seconds')::int AS offline_carts,
      COUNT(*) FILTER (WHERE latest.motion_status LIKE 'moving%')::int AS moving_carts,
      COUNT(*) FILTER (WHERE latest.motion_status NOT LIKE 'moving%' OR latest.motion_status IS NULL)::int AS stopped_carts,
      COUNT(*) FILTER (WHERE latest.battery_percentage < 20)::int AS low_battery_carts,
      COUNT(*) FILTER (WHERE latest.front_sensor_active = FALSE OR latest.left_sensor_active = FALSE OR latest.right_sensor_active = FALSE)::int AS sensor_error_carts,
      (SELECT COUNT(*)::int FROM alerts WHERE is_read = FALSE) AS active_alerts
    FROM carts
    LEFT JOIN latest ON latest.cart_id = carts.cart_id`
  );
  return result.rows[0];
}

async function cartAnalytics(cartId) {
  const result = await db.query(
    `SELECT
      AVG(battery_percentage)::numeric(8,2) AS average_battery,
      AVG(uptime_ms)::numeric(14,2) AS average_uptime_ms,
      COUNT(*) FILTER (WHERE motion_status = 'emergency_stop')::int AS emergency_stops,
      COUNT(*) FILTER (WHERE LOWER(stop_reason) LIKE '%obstacle%')::int AS obstacle_detections,
      COUNT(*) FILTER (WHERE front_sensor_active = FALSE OR left_sensor_active = FALSE OR right_sensor_active = FALSE)::int AS sensor_failures,
      COUNT(*) FILTER (WHERE motion_status LIKE 'moving%')::int AS moving_samples,
      COUNT(*) FILTER (WHERE motion_status NOT LIKE 'moving%')::int AS stopped_samples
     FROM telemetry WHERE cart_id = $1`,
    [cartId]
  );
  return result.rows[0];
}

async function batteryAnalytics() {
  const result = await db.query(
    `SELECT cart_id, AVG(battery_percentage)::numeric(8,2) AS average_battery,
      MIN(battery_percentage) AS min_battery, MAX(battery_percentage) AS max_battery
     FROM telemetry GROUP BY cart_id ORDER BY average_battery ASC`
  );
  return result.rows;
}

async function sensorAnalytics() {
  const result = await db.query(
    `SELECT cart_id,
      COUNT(*) FILTER (WHERE front_sensor_active = FALSE)::int AS front_failures,
      COUNT(*) FILTER (WHERE left_sensor_active = FALSE)::int AS left_failures,
      COUNT(*) FILTER (WHERE right_sensor_active = FALSE)::int AS right_failures
     FROM telemetry GROUP BY cart_id ORDER BY (COUNT(*) FILTER (WHERE front_sensor_active = FALSE OR left_sensor_active = FALSE OR right_sensor_active = FALSE)) DESC`
  );
  return result.rows;
}

module.exports = {
  summary,
  cartAnalytics,
  batteryAnalytics,
  sensorAnalytics
};
