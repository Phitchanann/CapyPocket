'use strict';

/**
 * Centralised error handler — must be registered last in app.js.
 * Normalises Joi validation errors, MySQL errors, and generic errors
 * into consistent JSON responses.
 */
module.exports = function errorHandler(err, req, res, _next) {
  // Log full error in dev, suppress in prod
  if (process.env.NODE_ENV !== 'production') {
    console.error('[ERROR]', err);
  }

  // Multer file-too-large
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ error: 'File too large — maximum 5 MB allowed' });
  }

  // MySQL: duplicate entry (e.g. unique email)
  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({ error: 'A record with those details already exists' });
  }

  // MySQL: foreign key violation
  if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    return res.status(400).json({ error: 'Referenced resource does not exist' });
  }

  // MySQL: check constraint (e.g. amount > 0)
  if (err.code === 'ER_CHECK_CONSTRAINT_VIOLATED') {
    return res.status(400).json({ error: 'Data violates a database constraint' });
  }

  const status  = err.status  || err.statusCode || 500;
  const message = err.message || 'Internal server error';

  res.status(status).json({ error: message });
};
