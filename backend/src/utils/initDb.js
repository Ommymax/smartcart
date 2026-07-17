const fs = require('fs');
const path = require('path');
const db = require('../config/db');

async function initDb() {
  const schema = fs.readFileSync(path.join(__dirname, '../config/schema.sql'), 'utf8');
  await db.query(schema);
  console.log('Database schema is ready.');
  await db.pool.end();
}

initDb().catch((error) => {
  console.error(error);
  process.exit(1);
});
