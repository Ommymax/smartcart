const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const db = require('../config/db');

async function seed() {
  const schema = fs.readFileSync(path.join(__dirname, '../config/schema.sql'), 'utf8');
  await db.query(schema);

  const adminPassword = await bcrypt.hash('Admin@12345', 12);
  const operatorPassword = await bcrypt.hash('Operator@12345', 12);

  const admin = await db.query(
    `INSERT INTO users (name, email, password_hash, role)
     VALUES ('Demo Admin', 'admin@smartcart.local', $1, 'administrator')
     ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name
     RETURNING id`,
    [adminPassword]
  );

  const operator = await db.query(
    `INSERT INTO users (name, email, password_hash, role)
     VALUES ('Demo Operator', 'operator@smartcart.local', $1, 'operator')
     ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name
     RETURNING id`,
    [operatorPassword]
  );

  await db.query(
    `INSERT INTO carts (cart_id, cart_name, description, serial_number, model, installation_date, assigned_user_id, status)
     VALUES
      ('SMART_CART_001', 'Entrance Cart 1', 'Customer-following demo cart', 'SC-001-2026', 'Prototype A', CURRENT_DATE, $1, 'active'),
      ('SMART_CART_002', 'Aisle Cart 2', 'Backup smart cart', 'SC-002-2026', 'Prototype A', CURRENT_DATE, $2, 'active')
     ON CONFLICT (cart_id) DO UPDATE SET cart_name = EXCLUDED.cart_name`,
    [operator.rows[0].id, admin.rows[0].id]
  );

  console.log('Seed complete.');
  console.log('Admin: admin@smartcart.local / Admin@12345');
  console.log('Operator: operator@smartcart.local / Operator@12345');
  await db.pool.end();
}

seed().catch((error) => {
  console.error(error);
  process.exit(1);
});
