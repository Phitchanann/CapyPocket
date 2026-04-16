'use strict';

const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const Joi    = require('joi');
const pool   = require('../config/db');

const SALT_ROUNDS = 10;

function signToken(userId) {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

// ── POST /auth/register ───────────────────────────────────────────────────────
const registerSchema = Joi.object({
  username:     Joi.string().max(100).required(),
  email:        Joi.string().email().required(),
  password:     Joi.string().min(6).max(128).required(),
  display_name: Joi.string().max(150).optional().allow(''),
});

exports.register = async (req, res, next) => {
  try {
    const { error, value } = registerSchema.validate(req.body, { abortEarly: true });
    if (error) return res.status(400).json({ error: error.details[0].message });

    const { username, email, password, display_name } = value;
    const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

    const [result] = await pool.execute(
      `INSERT INTO users (username, email, password_hash, is_guest, display_name)
       VALUES (?, ?, ?, 0, ?)`,
      [username, email, password_hash, display_name || username]
    );

    const userId = result.insertId;
    const token  = signToken(userId);

    return res.status(201).json({
      message: 'Registration successful',
      token,
      user: {
        id:           userId,
        username,
        email,
        display_name: display_name || username,
        is_guest:     false,
      },
    });
  } catch (err) {
    next(err);
  }
};

// ── POST /auth/login ──────────────────────────────────────────────────────────
const loginSchema = Joi.object({
  email:    Joi.string().email().required(),
  password: Joi.string().required(),
});

exports.login = async (req, res, next) => {
  try {
    const { error, value } = loginSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const { email, password } = value;

    const [rows] = await pool.execute(
      `SELECT id, username, email, password_hash, display_name, is_guest
       FROM users WHERE email = ? LIMIT 1`,
      [email]
    );

    if (rows.length === 0) {
      // Consistent timing even on miss — prevents user enumeration
      await bcrypt.compare(password, '$2b$10$invalidhashfortimingpurposesonly');
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user = rows[0];

    if (user.is_guest) {
      return res.status(401).json({ error: 'This account is a guest session and cannot log in with credentials' });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = signToken(user.id);

    return res.json({
      token,
      user: {
        id:           user.id,
        username:     user.username,
        email:        user.email,
        display_name: user.display_name,
        is_guest:     false,
      },
    });
  } catch (err) {
    next(err);
  }
};

// ── POST /auth/guest ──────────────────────────────────────────────────────────
exports.guest = async (req, res, next) => {
  try {
    // Generate a unique, collision-resistant guest username
    const guestUsername = `guest_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;

    const [result] = await pool.execute(
      `INSERT INTO users (username, email, password_hash, is_guest, display_name)
       VALUES (?, NULL, NULL, 1, 'Guest User')`,
      [guestUsername]
    );

    const userId = result.insertId;
    const token  = signToken(userId);

    return res.status(201).json({
      message: 'Guest session created',
      token,
      user: {
        id:           userId,
        username:     guestUsername,
        email:        null,
        display_name: 'Guest User',
        is_guest:     true,
      },
    });
  } catch (err) {
    next(err);
  }
};
