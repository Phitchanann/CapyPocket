'use strict';

const express      = require('express');
const router       = express.Router();
const authenticate = require('../middleware/auth');
const ctrl         = require('../controllers/transactionsController');

// All transaction routes require a valid JWT
router.use(authenticate);

// GET    /transactions
router.get('/', ctrl.getAll);

// POST   /transactions
router.post('/', ctrl.create);

// PUT    /transactions/:id
router.put('/:id', ctrl.update);

// DELETE /transactions/:id  (soft delete)
router.delete('/:id', ctrl.remove);

module.exports = router;
