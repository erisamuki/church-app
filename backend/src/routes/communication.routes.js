const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { query } = require('../database/connection');

router.get('/announcements', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      `SELECT * FROM announcements 
       WHERE church_id = $1 AND status = 'published' 
       AND (expire_at IS NULL OR expire_at > NOW())
       ORDER BY is_pinned DESC, created_at DESC LIMIT 20`,
      [req.user.church_id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

module.exports = router;