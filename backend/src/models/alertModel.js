const db = require('../config/db');

async function createAlert({ cartId, alertType, message, severity }) {
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

async function listAlerts({ unreadOnly, cartId, limit = 100 }) {
  const params = [];
  const clauses = [];
  if (unreadOnly === 'true') clauses.push('is_read = FALSE');
  if (cartId) {
    params.push(cartId);
    clauses.push(`cart_id = $${params.length}`);
  }
  params.push(Math.min(Number(limit) || 100, 500));
  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  const result = await db.query(
    `SELECT * FROM alerts ${where} ORDER BY created_at DESC LIMIT $${params.length}`,
    params
  );
  return result.rows;
}

async function findAlert(id) {
  const result = await db.query('SELECT * FROM alerts WHERE id = $1', [id]);
  return result.rows[0];
}

async function markRead(id) {
  const result = await db.query(
    'UPDATE alerts SET is_read = TRUE WHERE id = $1 RETURNING *',
    [id]
  );
  return result.rows[0];
}

async function deleteAlert(id) {
  const result = await db.query('DELETE FROM alerts WHERE id = $1 RETURNING *', [id]);
  return result.rows[0];
}

module.exports = {
  createAlert,
  listAlerts,
  findAlert,
  markRead,
  deleteAlert
};
