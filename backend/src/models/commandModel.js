const db = require('../config/db');

async function createCommand({ cartId, command, speed, durationMs, userId }) {
  const result = await db.query(
    `WITH superseded AS (
       UPDATE cart_commands
       SET consumed_at = NOW()
       WHERE cart_id = $1 AND consumed_at IS NULL
     )
     INSERT INTO cart_commands (cart_id, command, speed, duration_ms, source_user_id, expires_at)
     VALUES ($1, $2, $3, $4::integer, $5,
             NOW() + (($4::integer / 1000.0) * INTERVAL '1 second'))
     RETURNING *`,
    [cartId, command, speed, durationMs, userId || null]
  );
  return result.rows[0];
}

async function latestCommand(cartId) {
  const result = await db.query(
    `SELECT *
     FROM cart_commands
     WHERE cart_id = $1
       AND expires_at > NOW()
       AND consumed_at IS NULL
     ORDER BY created_at DESC
     LIMIT 1`,
    [cartId]
  );
  return result.rows[0] || null;
}

module.exports = {
  createCommand,
  latestCommand
};
