-- ============================================================
--  CapyPocket v2 — COMPLETE SINGLE SQL FILE
--  Schema + Seed Data (MySQL 8.0+, InnoDB, utf8mb4)
--
--  Run:  mysql -u root -p < CapyPocket.sql
--
--  ⚠️  Passwords in this file use SHA2 (for SQL compatibility).
--      For bcrypt login to work, also run:
--        cd capyproject/backend && npm run seed
--      seed.js will UPDATE the password_hash to a proper
--      bcrypt hash (test@example.com / 123456).
-- ============================================================

CREATE DATABASE IF NOT EXISTS capypocket
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE capypocket;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. USERS
--    New in v2: email, is_guest flag
--    password_hash: VARCHAR(255) to fit bcrypt (60 chars)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  username       VARCHAR(100)    NOT NULL,
  email          VARCHAR(255)    NULL,          -- nullable for guests
  password_hash  VARCHAR(255)    NULL,          -- bcrypt; nullable for guests
  is_guest       TINYINT(1)      NOT NULL DEFAULT 0,
  display_name   VARCHAR(150)    NOT NULL DEFAULT '',
  monthly_income DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
  cash_balance   DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
  pocket_saved   DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
  savings_goal   DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
  created_at     DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                          ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_users_username (username),
  UNIQUE KEY uk_users_email    (email)    -- NULL not treated as duplicate
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CATEGORIES
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id     BIGINT UNSIGNED NOT NULL,
  name        VARCHAR(100)    NOT NULL,
  icon_code   INT UNSIGNED    NOT NULL,
  color_value INT UNSIGNED    NOT NULL,
  updated_at  DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                       ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at  DATETIME(3)     NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_categories_user_name  (user_id, name),
  KEY        idx_categories_user_id   (user_id),
  CONSTRAINT fk_categories_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. TRANSACTIONS
--    receipt_image_url: URL returned by POST /upload/receipt
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id           BIGINT UNSIGNED NOT NULL,
  title             VARCHAR(255)    NOT NULL,
  category          VARCHAR(100)    NOT NULL,
  note              TEXT            NOT NULL,
  amount            DECIMAL(12,2)   NOT NULL,
  type              ENUM('expense','income','pocket') NOT NULL,
  receipt_image_url TEXT            NULL,
  created_at        DATETIME(3)     NOT NULL,
  updated_at        DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                             ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at        DATETIME(3)     NULL,
  PRIMARY KEY (id),
  KEY idx_transactions_user_id         (user_id),
  KEY idx_transactions_user_created_at (user_id, created_at),
  KEY idx_transactions_user_type       (user_id, type),
  KEY idx_transactions_user_category   (user_id, category),
  KEY idx_transactions_created_at      (created_at),
  KEY idx_transactions_type            (type),
  CONSTRAINT fk_transactions_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT chk_transactions_amount_positive
    CHECK (amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. GOALS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS goals (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       BIGINT UNSIGNED NOT NULL,
  name          VARCHAR(150)    NOT NULL,
  target_amount DECIMAL(12,2)   NOT NULL,
  saved_amount  DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
  created_at    DATETIME(3)     NOT NULL,
  updated_at    DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                         ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at    DATETIME(3)     NULL,
  PRIMARY KEY (id),
  KEY idx_goals_user_id         (user_id),
  KEY idx_goals_user_created_at (user_id, created_at),
  KEY idx_goals_created_at      (created_at),
  CONSTRAINT fk_goals_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT chk_goals_target_positive
    CHECK (target_amount > 0),
  CONSTRAINT chk_goals_saved_non_negative
    CHECK (saved_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
--  SEED DATA (idempotent — safe to run multiple times)
-- ============================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- USER 1 — Normal account
--   Login: test@example.com / 123456
--   ⚠️  password_hash below is a SHA2 placeholder.
--       Run "npm run seed" to replace it with a real bcrypt hash.
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO users (id, username, email, password_hash, is_guest, display_name,
                   monthly_income, cash_balance, pocket_saved, savings_goal)
SELECT 1, 'test.user', 'test@example.com',
       SHA2('123456', 256),   -- placeholder; npm run seed sets bcrypt hash
       0, 'Test User',
       35000.00, 15000.00, 5000.00, 20000.00
WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = 1);

-- ─────────────────────────────────────────────────────────────────────────────
-- USER 2 — Guest account (no email / no password)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO users (id, username, email, password_hash, is_guest, display_name)
SELECT 2, 'guest_seed', NULL, NULL, 1, 'Guest User'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = 2);

-- ─────────────────────────────────────────────────────────────────────────────
-- CATEGORIES — User 1
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO categories (user_id, name, icon_code, color_value)
VALUES
  (1, 'Food',     58743, 3761419878),
  (1, 'Bills',    58730, 3211486041),
  (1, 'Travel',   58718, 1334684777),
  (1, 'Pocket',   57534, 3278409813),
  (1, 'Shopping', 57405, 2607462093)
ON DUPLICATE KEY UPDATE
  icon_code   = VALUES(icon_code),
  color_value = VALUES(color_value);

-- ─────────────────────────────────────────────────────────────────────────────
-- CATEGORIES — User 2 (guest)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO categories (user_id, name, icon_code, color_value)
VALUES
  (2, 'Food',   58743, 3761419878),
  (2, 'Travel', 58718, 1334684777),
  (2, 'Other',  58923, 2088729755)
ON DUPLICATE KEY UPDATE
  icon_code   = VALUES(icon_code),
  color_value = VALUES(color_value);

-- ─────────────────────────────────────────────────────────────────────────────
-- TRANSACTIONS — User 1 (10 rows)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 1, 'April Salary', 'Pocket', 'Monthly salary deposit', 35000.00, 'income', '2026-04-01 09:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 1 AND title = 'April Salary' AND created_at = '2026-04-01 09:00:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 1, 'Grocery Run', 'Food', 'Weekly groceries at Tops', 920.50, 'expense', '2026-04-02 11:30:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 1 AND title = 'Grocery Run' AND created_at = '2026-04-02 11:30:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 1, 'Electric Bill', 'Bills', 'Monthly electricity', 480.00, 'expense', '2026-04-03 08:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 1 AND title = 'Electric Bill' AND created_at = '2026-04-03 08:00:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 1, 'Pocket Savings', 'Pocket', 'Monthly pocket transfer', 3000.00, 'pocket', '2026-04-04 10:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 1 AND title = 'Pocket Savings' AND created_at = '2026-04-04 10:00:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 1, 'Bus Monthly Pass', 'Travel', 'BTS/MRT monthly card', 300.00, 'expense', '2026-04-05 07:30:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 1 AND title = 'Bus Monthly Pass' AND created_at = '2026-04-05 07:30:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 1, 'Team Dinner', 'Food', 'Birthday dinner with team', 650.00, 'expense', '2026-04-08 19:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 1 AND title = 'Team Dinner' AND created_at = '2026-04-08 19:00:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 1, 'Freelance Payment', 'Pocket', 'Website redesign project', 5200.00, 'income', '2026-04-10 14:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 1 AND title = 'Freelance Payment' AND created_at = '2026-04-10 14:00:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 1, 'Internet Bill', 'Bills', 'Monthly fiber internet', 599.00, 'expense', '2026-04-10 08:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 1 AND title = 'Internet Bill' AND created_at = '2026-04-10 08:00:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 1, 'Shopping Mall', 'Shopping', 'New work clothes', 1800.00, 'expense', '2026-04-12 15:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 1 AND title = 'Shopping Mall' AND created_at = '2026-04-12 15:00:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 1, 'Morning Coffee', 'Food', 'Daily coffee + pastry', 85.00, 'expense', '2026-04-13 08:30:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 1 AND title = 'Morning Coffee' AND created_at = '2026-04-13 08:30:00.000');

-- ─────────────────────────────────────────────────────────────────────────────
-- TRANSACTIONS — User 2 / guest (5 rows)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 2, 'Street Pad Thai', 'Food', 'Lunch at street stall', 65.00, 'expense', '2026-04-14 12:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 2 AND title = 'Street Pad Thai' AND created_at = '2026-04-14 12:00:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 2, 'Taxi to Airport', 'Travel', 'Grab to Suvarnabhumi', 350.00, 'expense', '2026-04-14 16:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 2 AND title = 'Taxi to Airport' AND created_at = '2026-04-14 16:00:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 2, 'Iced Coffee', 'Food', 'Cafe Amazon', 45.00, 'expense', '2026-04-15 09:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 2 AND title = 'Iced Coffee' AND created_at = '2026-04-15 09:00:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 2, 'City Tour', 'Travel', 'Half-day guided tour', 800.00, 'expense', '2026-04-15 10:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 2 AND title = 'City Tour' AND created_at = '2026-04-15 10:00:00.000');

INSERT INTO transactions (user_id, title, category, note, amount, type, created_at)
SELECT 2, 'Souvenir Gift', 'Other', 'Elephant keychain set', 250.00, 'expense', '2026-04-15 17:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = 2 AND title = 'Souvenir Gift' AND created_at = '2026-04-15 17:00:00.000');

-- ─────────────────────────────────────────────────────────────────────────────
-- GOALS — User 1
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at)
SELECT 1, 'Emergency Fund', 50000.00, 15000.00, '2026-01-01 00:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM goals WHERE user_id = 1 AND name = 'Emergency Fund');

INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at)
SELECT 1, 'New MacBook Pro', 65000.00, 20000.00, '2026-02-15 00:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM goals WHERE user_id = 1 AND name = 'New MacBook Pro');

-- ─────────────────────────────────────────────────────────────────────────────
-- GOALS — User 2 (guest)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at)
SELECT 2, 'Travel Fund', 30000.00, 5000.00, '2026-03-01 00:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM goals WHERE user_id = 2 AND name = 'Travel Fund');

INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at)
SELECT 2, 'New Laptop', 25000.00, 8000.00, '2026-03-15 00:00:00.000'
WHERE NOT EXISTS (SELECT 1 FROM goals WHERE user_id = 2 AND name = 'New Laptop');

-- ─────────────────────────────────────────────────────────────────────────────
-- Done
-- ─────────────────────────────────────────────────────────────────────────────
SELECT 'CapyPocket v2 schema + seed: OK' AS status;
