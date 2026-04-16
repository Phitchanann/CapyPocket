'use strict';

require('dotenv').config();

const app  = require('./src/app');
const pool = require('./src/config/db');

const PORT = parseInt(process.env.PORT || '5000', 10);

async function start() {
  // Verify DB connection before accepting traffic
  try {
    const conn = await pool.getConnection();
    conn.release();
    console.log('MySQL connection: OK');
  } catch (err) {
    console.error('MySQL connection: FAILED —', err.message);
    console.error('Check DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME in .env');
    process.exit(1);
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`CapyPocket API running → http://localhost:${PORT}`);
    console.log(`  POST /auth/register`);
    console.log(`  POST /auth/login`);
    console.log(`  POST /auth/guest`);
    console.log(`  GET|POST /categories        (JWT required)`);
    console.log(`  GET|POST|PUT|DELETE /transactions/:id  (JWT required)`);
    console.log(`  GET|POST|PUT /goals/:id     (JWT required)`);
    console.log(`  POST /upload/receipt        (JWT required)`);
    console.log(`  GET  /health`);
  });
}

start();
