'use strict';

const Joi  = require('joi');
const pool = require('../config/db');

// ── GET /categories ───────────────────────────────────────────────────────────
exports.getAll = async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, name, icon_code, color_value
       FROM categories
       WHERE user_id = ? AND deleted_at IS NULL
       ORDER BY name ASC`,
      [req.userId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
};

// ── POST /categories ──────────────────────────────────────────────────────────
const createSchema = Joi.object({
  name:        Joi.string().max(100).required(),
  icon_code:   Joi.number().integer().min(0).required(),
  color_value: Joi.number().integer().min(0).required(),
});

exports.create = async (req, res, next) => {
  try {
    const { error, value } = createSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const [result] = await pool.execute(
      `INSERT INTO categories (user_id, name, icon_code, color_value)
       VALUES (?, ?, ?, ?)`,
      [req.userId, value.name, value.icon_code, value.color_value]
    );

    res.status(201).json({
      message:  'Category created',
      category: {
        id:          result.insertId,
        name:        value.name,
        icon_code:   value.icon_code,
        color_value: value.color_value,
      },
    });
  } catch (err) {
    next(err);
  }
};
