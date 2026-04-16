'use strict';

const multer = require('multer');
const path   = require('path');
const fs     = require('fs');

const UPLOADS_DIR = path.join(__dirname, '..', '..', 'uploads', 'receipts');
const MAX_SIZE_MB  = 5;
const ALLOWED_EXTS = new Set(['.jpg', '.jpeg', '.png', '.webp', '.heic']);

// Create the uploads directory on first use
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, UPLOADS_DIR),
  filename:    (req, file, cb) => {
    const ext  = path.extname(file.originalname).toLowerCase();
    const name = `receipt_${req.userId}_${Date.now()}${ext}`;
    cb(null, name);
  },
});

function fileFilter(_req, file, cb) {
  const ext = path.extname(file.originalname).toLowerCase();
  if (ALLOWED_EXTS.has(ext)) {
    cb(null, true);
  } else {
    cb(new Error(`Unsupported file type "${ext}". Allowed: jpg, png, webp, heic`), false);
  }
}

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: MAX_SIZE_MB * 1024 * 1024 },
});

/**
 * POST /upload/receipt
 * Expects multipart/form-data with a field named "receipt".
 * Returns { receipt_image_url } to save in transactions.receipt_image_url.
 */
exports.uploadReceipt = [
  upload.single('receipt'),
  (req, res, next) => {
    if (!req.file) {
      return res.status(400).json({ error: 'No file received — send as multipart/form-data, field name "receipt"' });
    }

    const baseUrl   = process.env.BASE_URL || `http://localhost:${process.env.PORT || 5000}`;
    const imageUrl  = `${baseUrl}/uploads/receipts/${req.file.filename}`;

    res.status(201).json({
      message:           'Receipt uploaded successfully',
      receipt_image_url: imageUrl,
    });
  },
];
