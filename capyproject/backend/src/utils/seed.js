'use strict';

/**
 * CapyPocket database seeder
 * Populates realistic sample data for development / demo purposes.
 *
 * Run: npm run seed
 *
 * The script is idempotent — it checks for existing data before inserting.
 * Safe to re-run; will skip if test@example.com already exists.
 */

require('dotenv').config({ path: require('path').join(__dirname, '..', '..', '.env') });

const bcrypt = require('bcryptjs');
const pool   = require('../config/db');

async function getOrCreate(table, whereField, whereValue, insertSql, insertParams) {
  const [rows] = await pool.execute(
    `SELECT id FROM ${table} WHERE ${whereField} = ? LIMIT 1`,
    [whereValue]
  );
  if (rows.length > 0) return rows[0].id;
  const [result] = await pool.execute(insertSql, insertParams);
  return result.insertId;
}

async function seed() {
  console.log('CapyPocket seeder starting...');

  // ── User 1: Normal account ──────────────────────────────────────────────────
  const hash1 = await bcrypt.hash('123456', 10);
  const uid1  = await getOrCreate(
    'users', 'email', 'test@example.com',
    `INSERT INTO users (username, email, password_hash, is_guest, display_name,
                        monthly_income, cash_balance, pocket_saved, savings_goal)
     VALUES ('test.user', 'test@example.com', ?, 0, 'Test User',
             35000.00, 15000.00, 5000.00, 20000.00)`,
    [hash1]
  );
  console.log(`  User 1 (test@example.com): id=${uid1}`);

  // ── User 2: Guest account ───────────────────────────────────────────────────
  const uid2 = await getOrCreate(
    'users', 'username', 'guest_seed',
    `INSERT INTO users (username, email, password_hash, is_guest, display_name)
     VALUES ('guest_seed', NULL, NULL, 1, 'Guest User')`,
    []
  );
  console.log(`  User 2 (guest_seed):        id=${uid2}`);

  // ── Categories ──────────────────────────────────────────────────────────────
  const cats1 = [
    ['Food',     0xe900, 0xE0542066],
    ['Bills',    0xe90a, 0xBF360C99],
    ['Travel',   0xe912, 0x4FC3F799],
    ['Pocket',   0xe91e, 0xC3915599],
    ['Shopping', 0xe928, 0x9B51C099],
  ];
  for (const [name, icon_code, color_value] of cats1) {
    await pool.execute(
      `INSERT IGNORE INTO categories (user_id, name, icon_code, color_value)
       VALUES (?, ?, ?, ?)`,
      [uid1, name, icon_code, color_value]
    );
  }

  const cats2 = [
    ['Food',   0xe900, 0xE0542066],
    ['Travel', 0xe912, 0x4FC3F799],
    ['Other',  0xe932, 0x78909C99],
  ];
  for (const [name, icon_code, color_value] of cats2) {
    await pool.execute(
      `INSERT IGNORE INTO categories (user_id, name, icon_code, color_value)
       VALUES (?, ?, ?, ?)`,
      [uid2, name, icon_code, color_value]
    );
  }
  console.log('  Categories seeded');

  // ── Transactions for User 1 ─────────────────────────────────────────────────
  // Only seed if this user has no transactions yet
  const [[{ cnt: txCnt1 }]] = await pool.execute(
    'SELECT COUNT(*) AS cnt FROM transactions WHERE user_id = ?', [uid1]
  );
  if (txCnt1 === 0) {
    const txs1 = [
      ['April Salary',       'Pocket',   'Monthly salary deposit',     35000.00, 'income',  '2026-04-01 09:00:00'],
      ['Grocery Run',        'Food',     'Weekly groceries at Tops',      920.50, 'expense', '2026-04-02 11:30:00'],
      ['Electric Bill',      'Bills',    'Monthly electricity',           480.00, 'expense', '2026-04-03 08:00:00'],
      ['Pocket Savings',     'Pocket',   'Monthly pocket transfer',      3000.00, 'pocket',  '2026-04-04 10:00:00'],
      ['Bus Monthly Pass',   'Travel',   'BTS/MRT monthly card',          300.00, 'expense', '2026-04-05 07:30:00'],
      ['Team Dinner',        'Food',     'Birthday dinner with team',     650.00, 'expense', '2026-04-08 19:00:00'],
      ['Freelance Payment',  'Pocket',   'Website redesign project',     5200.00, 'income',  '2026-04-10 14:00:00'],
      ['Internet Bill',      'Bills',    'Monthly fiber internet',        599.00, 'expense', '2026-04-10 08:00:00'],
      ['Shopping Mall',      'Shopping', 'New work clothes',             1800.00, 'expense', '2026-04-12 15:00:00'],
      ['Morning Coffee',     'Food',     'Daily coffee + pastry',          85.00, 'expense', '2026-04-13 08:30:00'],
    ];
    for (const [title, category, note, amount, type, created_at] of txs1) {
      await pool.execute(
        `INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [uid1, title, category, note, amount, type, new Date(created_at)]
      );
    }
    console.log(`  Transactions for User 1: ${txs1.length} rows`);
  } else {
    console.log(`  Transactions for User 1: already seeded (${txCnt1} rows)`);
  }

  // ── Transactions for User 2 (guest) ────────────────────────────────────────
  const [[{ cnt: txCnt2 }]] = await pool.execute(
    'SELECT COUNT(*) AS cnt FROM transactions WHERE user_id = ?', [uid2]
  );
  if (txCnt2 === 0) {
    const txs2 = [
      ['Street Pad Thai',   'Food',   'Lunch at street stall',   65.00, 'expense', '2026-04-14 12:00:00'],
      ['Taxi to Airport',   'Travel', 'Grab to Suvarnabhumi',   350.00, 'expense', '2026-04-14 16:00:00'],
      ['Iced Coffee',       'Food',   'Cafe Amazon',              45.00, 'expense', '2026-04-15 09:00:00'],
      ['City Tour',         'Travel', 'Half-day guided tour',   800.00, 'expense', '2026-04-15 10:00:00'],
      ['Souvenir Gift',     'Other',  'Elephant keychain set',  250.00, 'expense', '2026-04-15 17:00:00'],
    ];
    for (const [title, category, note, amount, type, created_at] of txs2) {
      await pool.execute(
        `INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [uid2, title, category, note, amount, type, new Date(created_at)]
      );
    }
    console.log(`  Transactions for User 2: ${txs2.length} rows`);
  } else {
    console.log(`  Transactions for User 2: already seeded (${txCnt2} rows)`);
  }

  // ── Goals for User 1 ────────────────────────────────────────────────────────
  const [[{ cnt: gCnt1 }]] = await pool.execute(
    'SELECT COUNT(*) AS cnt FROM goals WHERE user_id = ?', [uid1]
  );
  if (gCnt1 === 0) {
    await pool.execute(
      `INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at) VALUES (?, ?, ?, ?, ?)`,
      [uid1, 'Emergency Fund', 50000.00, 15000.00, new Date('2026-01-01')]
    );
    await pool.execute(
      `INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at) VALUES (?, ?, ?, ?, ?)`,
      [uid1, 'New MacBook Pro', 65000.00, 20000.00, new Date('2026-02-15')]
    );
    console.log('  Goals for User 1: 2 rows');
  } else {
    console.log(`  Goals for User 1: already seeded (${gCnt1} rows)`);
  }

  // ── Goals for User 2 (guest) ────────────────────────────────────────────────
  const [[{ cnt: gCnt2 }]] = await pool.execute(
    'SELECT COUNT(*) AS cnt FROM goals WHERE user_id = ?', [uid2]
  );
  if (gCnt2 === 0) {
    await pool.execute(
      `INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at) VALUES (?, ?, ?, ?, ?)`,
      [uid2, 'Travel Fund', 30000.00, 5000.00, new Date('2026-03-01')]
    );
    await pool.execute(
      `INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at) VALUES (?, ?, ?, ?, ?)`,
      [uid2, 'New Laptop', 25000.00, 8000.00, new Date('2026-03-15')]
    );
    console.log('  Goals for User 2: 2 rows');
  } else {
    console.log(`  Goals for User 2: already seeded (${gCnt2} rows)`);
  }

  console.log('\nSeed complete!');
  console.log('  Login: test@example.com / 123456');
  await pool.end();
}

seed().catch(err => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});
