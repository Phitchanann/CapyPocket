'use strict';

const express      = require('express');
const router       = express.Router();
const authenticate = require('../middleware/auth');
const ctrl         = require('../controllers/goalsController');

// All goal routes require a valid JWT
router.use(authenticate);

// GET  /goals
router.get('/', ctrl.getAll);

// POST /goals
router.post('/', ctrl.create);

// PUT  /goals/:id
router.put('/:id', ctrl.update);

module.exports = router;
