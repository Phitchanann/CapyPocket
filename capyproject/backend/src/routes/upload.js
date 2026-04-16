'use strict';

const express      = require('express');
const router       = express.Router();
const authenticate = require('../middleware/auth');
const ctrl         = require('../controllers/uploadController');

// POST /upload/receipt  — multipart/form-data, field name: "receipt"
router.post('/receipt', authenticate, ctrl.uploadReceipt);

module.exports = router;
