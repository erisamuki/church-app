const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { query } = require('../database/connection');

router.get('/', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      `SELECT g.*, 
        COUNT(gm.member_id) as member_count,
        m.first_name as leader_first_name, m.last_name as leader_last_name
       FROM small_groups g
       LEFT JOIN group_members gm ON g.id = gm.group_id
       LEFT JOIN members m ON g.leader_id = m.id
       WHERE g.church_id = $1 AND g.is_active = true
       GROUP BY g.id, m.first_name, m.last_name
       ORDER BY g.name`,
      [req.user.church_id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

router.get('/:id/members', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      `SELECT m.id, m.first_name, m.last_name, m.email, m.phone, m.photo_url, gm.role, gm.joined_at
       FROM group_members gm
       JOIN members m ON gm.member_id = m.id
       WHERE gm.group_id = $1 ORDER BY gm.role, m.last_name`,
      [req.params.id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

module.exports = router;