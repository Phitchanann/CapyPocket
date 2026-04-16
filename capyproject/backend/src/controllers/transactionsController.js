'use strict';

const Joi  = require('joi');
const pool = require('../config/db');

/**
 * Normalise a DB row for JSON output.
 * - amount → float (DECIMAL comes as string from mysql2)
 * - created_at → ISO 8601 string (Date object from mysql2)
 * - receipt_image_url → string or null
 */
function formatRow(row) {
  return {
    id:                row.id,
    title:             row.title,
    category:          row.category,
    note:              row.note,
    amount:            parseFloat(row.amount),
    type:              row.type,
    receipt_image_url: row.receipt_image_url || null,
    created_at:        row.created_at instanceof Date
                         ? row.created_at.toISOString()
                         : String(row.created_at),
  };
}

/** Convert ISO 8601 string → JS Date for mysql2 DATETIME insertion */
function parseDate(isoStr) {
  return new Date(isoStr);
}

// ── GET /transactions ─────────────────────────────────────────────────────────
exports.getAll = async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, title, category, note, amount, type, receipt_image_url, created_at
       FROM transactions
       WHERE user_id = ? AND deleted_at IS NULL
       ORDER BY created_at DESC`,
      [req.userId]
    );
    res.json(rows.map(formatRow));
  } catch (err) {
    next(err);
  }
};

// ── POST /transactions ────────────────────────────────────────────────────────
const createSchema = Joi.object({
  title:             Joi.string().max(255).required(),
  category:          Joi.string().max(100).required(),
  note:              Joi.string().allow('').default(''),
  amount:            Joi.number().positive().required(),
  type:              Joi.string().valid('expense', 'income', 'pocket').required(),
  receipt_image_url: Joi.string().uri().allow(null, '').optional().default(null),
  created_at:        Joi.string().isoDate().required(),
});

exports.create = async (req, res, next) => {
  try {
    const { error, value } = createSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const [result] = await pool.execute(
      `INSERT INTO transactions
         (user_id, title, category, note, amount, type, receipt_image_url, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.userId,
        value.title,
        value.category,
        value.note,
        value.amount,
        value.type,
        value.receipt_image_url || null,
        parseDate(value.created_at),
      ]
    );

    res.status(201).json({
      message:     'Transaction created',
      transaction: { id: result.insertId, ...value },
    });
  } catch (err) {
    next(err);
  }
};

// ── PUT /transactions/:id ─────────────────────────────────────────────────────
const updateSchema = Joi.object({
  title:             Joi.string().max(255).required(),
  category:          Joi.string().max(100).required(),
  note:              Joi.string().allow('').default(''),
  amount:            Joi.number().positive().required(),
  type:              Joi.string().valid('expense', 'income', 'pocket').required(),
  receipt_image_url: Joi.string().uri().allow(null, '').optional().default(null),
  created_at:        Joi.string().isoDate().required(),
});

exports.update = async (req, res, next) => {
  try {
    const { error, value } = updateSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const [result] = await pool.execute(
      `UPDATE transactions
       SET title = ?, category = ?, note = ?, amount = ?, type = ?,
           receipt_image_url = ?, created_at = ?
       WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
      [
        value.title,
        value.category,
        value.note,
        value.amount,
        value.type,
        value.receipt_image_url || null,
        parseDate(value.created_at),
        req.params.id,
        req.userId,
      ]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Transaction not found' });
    }

    res.json({ message: 'Transaction updated' });
  } catch (err) {
    next(err);
  }
};

// ── DELETE /transactions/:id (soft delete) ────────────────────────────────────
exports.remove = async (req, res, next) => {
  try {
    const [result] = await pool.execute(
      `UPDATE transactions
       SET deleted_at = NOW(3)
       WHERE id = ? AND user_id = ? AND deleted_at IS NULL`,
      [req.params.id, req.userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Transaction not found' });
    }

    res.json({ message: `Transaction ${req.params.id} deleted` });
  } catch (err) {
    next(err);
  }
};
