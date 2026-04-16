'use strict';

const Joi  = require('joi');
const pool = require('../config/db');

function formatRow(row) {
  return {
    id:            row.id,
    name:          row.name,
    target_amount: parseFloat(row.target_amount),
    saved_amount:  parseFloat(row.saved_amount),
    created_at:    row.created_at instanceof Date
                     ? row.created_at.toISOString()
                     : String(row.created_at),
  };
}

function parseDate(isoStr) {
  return new Date(isoStr);
}

// ── GET /goals ────────────────────────────────────────────────────────────────
exports.getAll = async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, name, target_amount, saved_amount, created_at
       FROM goals
       WHERE user_id = ? AND deleted_at IS NULL
       ORDER BY created_at DESC`,
      [req.userId]
    );
    res.json(rows.map(formatRow));
  } catch (err) {
    next(err);
  }
};

// ── POST /goals ───────────────────────────────────────────────────────────────
const goalSchema = Joi.object({
  name:          Joi.string().max(150).required(),
  target_amount: Joi.number().positive().required(),
  saved_amount:  Joi.number().min(0).default(0),
  created_at:    Joi.string().isoDate().required(),
});

exports.create = async (req, res, next) => {
  try {
    const { error, value } = goalSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const [result] = await pool.execute(
      `INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at)
       VALUES (?, ?, ?, ?, ?)`,
      [
        req.userId,
        value.name,
        value.target_amount,
        value.saved_amount,
        parseDate(value.created_at),
      ]
    );

    res.status(201).json({
      message: 'Goal created',
      goal:    { id: result.insertId, ...value },
    });
  } catch (err) {
    next(err);
  }
};

// ── PUT /goals/:id ────────────────────────────────────────────────────────────
exports.update = async (req, res, next) => {
  try {
    const { error, value } = goalSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const [result] = await pool.execute(
      `UPDATE goals
       SET name = ?, target_amount = ?, saved_amount = ?, created_at = ?
       WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
      [
        value.name,
        value.target_amount,
        value.saved_amount,
        parseDate(value.created_at),
        req.params.id,
        req.userId,
      ]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Goal not found' });
    }

    res.json({ message: 'Goal updated' });
  } catch (err) {
    next(err);
  }
};
