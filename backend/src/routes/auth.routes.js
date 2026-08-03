const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const Joi = require('joi');
const rateLimit = require('express-rate-limit');
const { query } = require('../database/connection');
const { authenticate, authorize } = require('../middleware/auth');
const { sendPasswordResetEmail } = require('../services/email.service');

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required()
});

const registerSchema = Joi.object({
  church_id: Joi.string().uuid().required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required(),
  first_name: Joi.string().min(1).max(100).required(),
  last_name: Joi.string().min(1).max(100).required(),
  phone: Joi.string().allow(''),
  role: Joi.string().valid('admin', 'pastor', 'staff').default('staff')
});

const forgotPasswordSchema = Joi.object({
  email: Joi.string().email().required()
});

const resetPasswordSchema = Joi.object({
  email: Joi.string().email().required(),
  code: Joi.string().length(6).required(),
  new_password: Joi.string().min(8).required()
});

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { success: false, message: 'Too many login attempts. Please try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 3,
  message: { success: false, message: 'Too many reset requests. Please try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// POST /api/auth/login
router.post('/login', loginLimiter, async (req, res, next) => {
  try {
    const { error } = loginSchema.validate(req.body);
    if (error) return res.status(400).json({ success: false, message: error.details[0].message });

    const { email, password } = req.body;
    const result = await query(
      'SELECT id, church_id, email, password_hash, first_name, last_name, role, is_active FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });
    }

    const user = result.rows[0];
    if (!user.is_active) {
      return res.status(401).json({ success: false, message: 'Account is deactivated.' });
    }

    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) {
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });
    }

    await query('UPDATE users SET last_login = NOW() WHERE id = $1', [user.id]);

    const token = jwt.sign(
      { userId: user.id, churchId: user.church_id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        church_id: user.church_id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role
      }
    });
  } catch (err) { next(err); }
});

// POST /api/auth/register  (admin-only)
router.post('/register', authenticate, authorize('admin'), async (req, res, next) => {
  try {
    const { error } = registerSchema.validate(req.body);
    if (error) return res.status(400).json({ success: false, message: error.details[0].message });

    const { church_id, email, password, first_name, last_name, phone, role } = req.body;

    const existing = await query('SELECT id FROM users WHERE email = $1', [email.toLowerCase()]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ success: false, message: 'Email already registered.' });
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const result = await query(
      `INSERT INTO users (church_id, email, password_hash, first_name, last_name, phone, role)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id, email, first_name, last_name, role`,
      [church_id, email.toLowerCase(), hashedPassword, first_name, last_name, phone || null, role]
    );

    res.status(201).json({ success: true, user: result.rows[0] });
  } catch (err) { next(err); }
});

// POST /api/auth/forgot-password
router.post('/forgot-password', forgotPasswordLimiter, async (req, res, next) => {
  try {
    const { error } = forgotPasswordSchema.validate(req.body);
    if (error) return res.status(400).json({ success: false, message: error.details[0].message });

    const { email } = req.body;
    const result = await query(
      'SELECT id, first_name, email FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    // Always respond success, even if email not found — avoids leaking which emails are registered
    if (result.rows.length === 0) {
      return res.json({ success: true, message: 'If that email is registered, a reset code has been sent.' });
    }

    const user = result.rows[0];
    const code = crypto.randomInt(100000, 999999).toString(); // 6-digit code
    const hashedCode = crypto.createHash('sha256').update(code).digest('hex');
    const expires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    await query(
      'UPDATE users SET reset_token = $1, reset_token_expires = $2 WHERE id = $3',
      [hashedCode, expires, user.id]
    );

    await sendPasswordResetEmail(user.email, user.first_name, code);

    res.json({ success: true, message: 'If that email is registered, a reset code has been sent.' });
  } catch (err) { next(err); }
});

// POST /api/auth/reset-password
router.post('/reset-password', async (req, res, next) => {
  try {
    const { error } = resetPasswordSchema.validate(req.body);
    if (error) return res.status(400).json({ success: false, message: error.details[0].message });

    const { email, code, new_password } = req.body;
    const hashedCode = crypto.createHash('sha256').update(code).digest('hex');

    const result = await query(
      `SELECT id, reset_token, reset_token_expires FROM users WHERE email = $1`,
      [email.toLowerCase()]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ success: false, message: 'Invalid or expired code.' });
    }

    const user = result.rows[0];
    if (
      !user.reset_token ||
      user.reset_token !== hashedCode ||
      !user.reset_token_expires ||
      new Date(user.reset_token_expires) < new Date()
    ) {
      return res.status(400).json({ success: false, message: 'Invalid or expired code.' });
    }

    const hashedPassword = await bcrypt.hash(new_password, 12);
    await query(
      'UPDATE users SET password_hash = $1, reset_token = NULL, reset_token_expires = NULL WHERE id = $2',
      [hashedPassword, user.id]
    );

    res.json({ success: true, message: 'Password reset successfully. You can now log in.' });
  } catch (err) { next(err); }
});

// GET /api/auth/me
router.get('/me', authenticate, async (req, res) => {
  res.json({ success: true, user: req.user });
});

module.exports = router;