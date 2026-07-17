const db = require('../config/db');

const publicFields = 'id, name, email, role, created_at, updated_at';

async function createUser({ name, email, passwordHash, role }) {
  const result = await db.query(
    `INSERT INTO users (name, email, password_hash, role)
     VALUES ($1, $2, $3, $4)
     RETURNING ${publicFields}`,
    [name, email.toLowerCase(), passwordHash, role]
  );
  return result.rows[0];
}

async function findByEmail(email) {
  const result = await db.query('SELECT * FROM users WHERE email = $1', [email.toLowerCase()]);
  return result.rows[0];
}

async function findById(id) {
  const result = await db.query(`SELECT ${publicFields} FROM users WHERE id = $1`, [id]);
  return result.rows[0];
}

async function listUsers() {
  const result = await db.query(`SELECT ${publicFields} FROM users ORDER BY created_at DESC`);
  return result.rows;
}

module.exports = {
  createUser,
  findByEmail,
  findById,
  listUsers
};
