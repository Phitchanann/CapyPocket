'use strict';

const express      = require('express');
const router       = express.Router();
const authenticate = require('../middleware/auth');
const ctrl         = require('../controllers/categoriesController');

// All category routes require a valid JWT
router.use(authenticate);

// GET  /categories
router.get('/', ctrl.getAll);

// POST /categories
router.post('/', ctrl.create);

module.exports = router;
