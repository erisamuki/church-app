const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { query } = require('../database/connection');

// GET /api/notifications
router.get('/', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      `SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 30`,
      [req.user.id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

// GET /api/notifications/unread-count
router.get('/unread-count', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      `SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false`,
      [req.user.id]
    );
    res.json({ success: true, data: { count: parseInt(result.rows[0].count) } });
  } catch (err) { next(err); }
});

// PUT /api/notifications/:id/read
router.put('/:id/read', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      `UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2 RETURNING *`,
      [req.params.id, req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Notification not found' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// PUT /api/notifications/read-all
router.put('/read-all', authenticate, async (req, res, next) => {
  try {
    await query(
      `UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false`,
      [req.user.id]
    );
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (err) { next(err); }
});

module.exports = router;