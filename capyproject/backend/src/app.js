'use strict';

const express = require('express');
const cors    = require('cors');
const path    = require('path');

const authRoutes         = require('./routes/auth');
const categoriesRoutes   = require('./routes/categories');
const transactionsRoutes = require('./routes/transactions');
const goalsRoutes        = require('./routes/goals');
const uploadRoutes       = require('./routes/upload');
const errorHandler       = require('./middleware/errorHandler');

const app = express();

// ── Middleware ────────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded receipt images as static files
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/auth',         authRoutes);
app.use('/categories',   categoriesRoutes);
app.use('/transactions', transactionsRoutes);
app.use('/goals',        goalsRoutes);
app.use('/upload',       uploadRoutes);

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ ok: true, timestamp: new Date().toISOString() });
});

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.path}` });
});

// ── Global error handler (must be last) ───────────────────────────────────────
app.use(errorHandler);

module.exports = app;
