const express = require('express');
const router = express.Router();
const { query, transaction } = require('../database/connection');
const { authenticate, authorize } = require('../middleware/auth');

// GET /api/events
router.get('/', authenticate, async (req, res, next) => {
  try {
    const { type, from, to, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    let where = 'WHERE church_id = $1';
    let params = [req.user.church_id];
    let p = 1;

    if (type) { p++; where += ` AND event_type = $${p}`; params.push(type); }
    if (from) { p++; where += ` AND start_datetime >= $${p}`; params.push(from); }
    if (to) { p++; where += ` AND start_datetime <= $${p}`; params.push(to); }

    params.push(parseInt(limit), offset);
    const result = await query(
      `SELECT e.*, COUNT(ea.id) as registered_count 
       FROM events e LEFT JOIN event_attendance ea ON e.id = ea.event_id
       ${where} GROUP BY e.id ORDER BY start_datetime DESC LIMIT $${p + 1} OFFSET $${p + 2}`,
      params
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

// POST /api/events
router.post('/', authenticate, authorize('admin', 'pastor', 'staff'), async (req, res, next) => {
  try {
    const { title, description, event_type, start_datetime, end_datetime, location, max_attendees } = req.body;
    const result = await query(
      `INSERT INTO events (church_id, title, description, event_type, start_datetime, end_datetime, location, max_attendees, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
      [req.user.church_id, title, description, event_type, start_datetime, end_datetime, location, max_attendees, req.user.id]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// POST /api/events/:id/checkin
router.post('/:id/checkin', authenticate, async (req, res, next) => {
  try {
    const { member_id, guest_name, guest_email, guest_phone } = req.body;
    const result = await query(
      `INSERT INTO event_attendance (event_id, member_id, guest_name, guest_email, guest_phone, checked_in_by, check_in_method)
       VALUES ($1, $2, $3, $4, $5, $6, 'app') RETURNING *`,
      [req.params.id, member_id || null, guest_name || null, guest_email || null, guest_phone || null, req.user.id]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// GET /api/events/:id/attendance
router.get('/:id/attendance', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      `SELECT ea.*, m.first_name, m.last_name, m.email, m.phone
       FROM event_attendance ea
       LEFT JOIN members m ON ea.member_id = m.id
       WHERE ea.event_id = $1 ORDER BY ea.checked_in_at DESC`,
      [req.params.id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

module.exports = router;