const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { query } = require('../database/connection');

router.get('/roles', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      'SELECT * FROM volunteer_roles WHERE church_id = $1 AND is_active = true ORDER BY name',
      [req.user.church_id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

router.get('/assignments/:eventId', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      `SELECT va.*, m.first_name, m.last_name, r.name as role_name, r.color, r.department
       FROM volunteer_assignments va
       JOIN members m ON va.member_id = m.id
       JOIN volunteer_roles r ON va.role_id = r.id
       WHERE va.event_id = $1 ORDER BY r.department, r.name`,
      [req.params.eventId]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

module.exports = router;