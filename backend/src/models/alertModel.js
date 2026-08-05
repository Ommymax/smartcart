const db = require('../config/db');

async function createAlert({ cartId, alertType, message, severity }) {
  await db.query('DELETE FROM alert_dismissals WHERE dismissed_until <= NOW()');

  const dismissed = await db.query(
    `SELECT 1 FROM alert_dismissals
     WHERE cart_id = $1 AND alert_type = $2 AND dismissed_until > NOW()
     LIMIT 1`,
    [cartId, alertType]
  );
  if (dismissed.rows[0]) return null;

  const duplicate = await db.query(
    `SELECT id FROM alerts
     WHERE cart_id = $1 AND alert_type = $2 AND is_read = FALSE
       AND created_at > NOW() - INTERVAL '5 minutes'
     LIMIT 1`,
    [cartId, alertType]
  );
  if (duplicate.rows[0]) return null;

  const result = await db.query(
    `INSERT INTO alerts (cart_id, alert_type, message, severity)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [cartId, alertType, message, severity]
  );
  return result.rows[0];
}

function applyAlertScope({ params, clauses, user }) {
  if (user?.role === 'operator') {
    params.push(user.id);
    clauses.push(`c.assigned_user_id = $${params.length}`);
  }
}

async function listAlerts({ unreadOnly, cartId, limit = 100 }, user) {
  const params = [];
  const clauses = [];
  if (unreadOnly === 'true') clauses.push('a.is_read = FALSE');
  if (cartId) {
    params.push(cartId);
    clauses.push(`a.cart_id = $${params.length}`);
  }
  applyAlertScope({ params, clauses, user });
  params.push(Math.min(Number(limit) || 100, 500));
  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  const result = await db.query(
    `SELECT a.*, c.cart_name
     FROM alerts a
     JOIN carts c ON c.cart_id = a.cart_id
     ${where}
     ORDER BY a.created_at DESC LIMIT $${params.length}`,
    params
  );
  return result.rows;
}

async function findAlert(id, user) {
  const params = [id];
  const clauses = ['a.id = $1'];
  applyAlertScope({ params, clauses, user });
  const result = await db.query(
    `SELECT a.*, c.cart_name
     FROM alerts a
     JOIN carts c ON c.cart_id = a.cart_id
     WHERE ${clauses.join(' AND ')}`,
    params
  );
  return result.rows[0];
}

async function markRead(id, user) {
  const alert = await findAlert(id, user);
  if (!alert) return null;
  const result = await db.query(
    'UPDATE alerts SET is_read = TRUE WHERE id = $1 RETURNING *',
    [id]
  );
  return result.rows[0];
}

async function deleteAlert(id, user) {
  const existing = await findAlert(id, user);
  if (!existing) return null;
  const result = await db.query('DELETE FROM alerts WHERE id = $1 RETURNING *', [id]);
  const alert = result.rows[0];
  if (alert) await suppressAlert(alert.cart_id, alert.alert_type);
  return alert;
}

async function deleteAlerts({ cartId } = {}, user) {
  const params = [];
  const clauses = [];
  if (cartId) {
    params.push(cartId);
    clauses.push(`a.cart_id = $${params.length}`);
  }
  applyAlertScope({ params, clauses, user });
  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  const result = await db.query(
    `DELETE FROM alerts a
     USING carts c
     ${where ? `${where} AND` : 'WHERE'} c.cart_id = a.cart_id
     RETURNING a.*`,
    params
  );
  for (const alert of result.rows) {
    await suppressAlert(alert.cart_id, alert.alert_type);
  }
  return result.rows;
}

async function dismissAlert(cartId, alertType, minutes = 30) {
  await db.query(
    `INSERT INTO alert_dismissals (cart_id, alert_type, dismissed_until)
     VALUES ($1, $2, NOW() + ($3::text || ' minutes')::interval)
     ON CONFLICT (cart_id, alert_type)
     DO UPDATE SET dismissed_until = EXCLUDED.dismissed_until`,
    [cartId, alertType, minutes]
  );
}

async function suppressAlert(cartId, alertType) {
  await db.query(
    `INSERT INTO alert_dismissals (cart_id, alert_type, dismissed_until)
     VALUES ($1, $2, 'infinity'::timestamptz)
     ON CONFLICT (cart_id, alert_type)
     DO UPDATE SET dismissed_until = EXCLUDED.dismissed_until`,
    [cartId, alertType]
  );
}

module.exports = {
  createAlert,
  listAlerts,
  findAlert,
  markRead,
  deleteAlert,
  deleteAlerts,
  dismissAlert,
  suppressAlert
};
