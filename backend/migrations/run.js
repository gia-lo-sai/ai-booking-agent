require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

async function runMigrations() {
  console.log('🔄 Esecuzione migrazioni database...');

  try {
    const schemaPath = path.join(__dirname, '..', 'database', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');

    await pool.query(schema);

    console.log('✅ Migrazioni completate con successo!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Errore durante le migrazioni:', error);
    process.exit(1);
  }
}

runMigrations();
