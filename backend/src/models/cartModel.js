const db = require('../config/db');

async function listCarts({ assignedUserId, role }) {
  const params = [];
  let where = '';
  if (role === 'operator') {
    params.push(assignedUserId);
    where = 'WHERE c.assigned_user_id = $1';
  }

  const result = await db.query(
    `SELECT c.*,
      u.name AS assigned_user_name,
      t.power_status, t.motion_status, t.stop_reason, t.battery_voltage,
      t.battery_percentage, t.radio_connected, t.internet_connected,
      t.front_sensor_active, t.left_sensor_active, t.right_sensor_active,
      t.left_rssi, t.right_rssi, t.location_available, t.latitude, t.longitude,
      t.uptime_ms, t.created_at AS last_telemetry_at
     FROM carts c
     LEFT JOIN users u ON u.id = c.assigned_user_id
     LEFT JOIN LATERAL (
       SELECT * FROM telemetry WHERE telemetry.cart_id = c.cart_id ORDER BY created_at DESC LIMIT 1
     ) t ON TRUE
     ${where}
     ORDER BY c.created_at DESC`,
    params
  );
  return result.rows;
}

async function findByCartId(cartId) {
  const result = await db.query('SELECT * FROM carts WHERE cart_id = $1', [cartId]);
  return result.rows[0];
}

async function createCart(data) {
  const result = await db.query(
    `INSERT INTO carts (cart_id, cart_name, description, serial_number, model, installation_date, assigned_user_id, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
    [
      data.cartId,
      data.cartName,
      data.description || null,
      data.serialNumber || null,
      data.model || null,
      data.installationDate || null,
      data.assignedUserId || null,
      data.status || 'active'
    ]
  );
  return result.rows[0];
}

async function createCartForUser(data, assignedUserId) {
  return createCart({
    ...data,
    assignedUserId,
    status: data.status || 'active'
  });
}

async function assignCartToUser(cartId, assignedUserId) {
  const result = await db.query(
    `UPDATE carts
     SET assigned_user_id = $2,
         updated_at = NOW()
     WHERE cart_id = $1
     RETURNING *`,
    [cartId, assignedUserId]
  );
  return result.rows[0];
}

async function updateCart(cartId, data) {
  const result = await db.query(
    `UPDATE carts
     SET cart_name = COALESCE($2, cart_name),
         description = COALESCE($3, description),
         serial_number = COALESCE($4, serial_number),
         model = COALESCE($5, model),
         installation_date = COALESCE($6, installation_date),
         assigned_user_id = COALESCE($7, assigned_user_id),
         status = COALESCE($8, status),
         updated_at = NOW()
     WHERE cart_id = $1
     RETURNING *`,
    [
      cartId,
      data.cartName,
      data.description,
      data.serialNumber,
      data.model,
      data.installationDate,
      data.assignedUserId,
      data.status
    ]
  );
  return result.rows[0];
}

async function deleteCart(cartId) {
  const result = await db.query('DELETE FROM carts WHERE cart_id = $1 RETURNING *', [cartId]);
  return result.rows[0];
}

module.exports = {
  listCarts,
  findByCartId,
  createCart,
  createCartForUser,
  assignCartToUser,
  updateCart,
  deleteCart
};
