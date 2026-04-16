'use strict';

const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/authController');

// POST /auth/register  — create a new account (email + password)
router.post('/register', ctrl.register);

// POST /auth/login     — authenticate and receive JWT
router.post('/login', ctrl.login);

// POST /auth/guest     — create a temporary guest session (no credentials)
router.post('/guest', ctrl.guest);

module.exports = router;
