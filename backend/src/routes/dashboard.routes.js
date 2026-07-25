const express = require('express');
const router = express.Router();
const { query } = require('../database/connection');
const { authenticate } = require('../middleware/auth');

router.get('/stats', authenticate, async (req, res, next) => {
  try {
    const churchId = req.user.church_id;

    const [members, attendance, giving, volunteers] = await Promise.all([
      query('SELECT COUNT(*) FROM members WHERE church_id = $1 AND membership_status IN ($2, $3)', [churchId, 'member', 'active']),
      query(`SELECT COUNT(*) FROM event_attendance ea 
             JOIN events e ON ea.event_id = e.id 
             WHERE e.church_id = $1 AND e.start_datetime >= DATE_TRUNC('week', NOW())`, [churchId]),
      query(`SELECT COALESCE(SUM(amount), 0) as total FROM donations WHERE church_id = $1 AND donation_date >= DATE_TRUNC('month', NOW())`, [churchId]),
      query(`SELECT COUNT(DISTINCT member_id) FROM volunteer_assignments va 
             JOIN events e ON va.event_id = e.id 
             WHERE e.church_id = $1 AND e.start_datetime >= DATE_TRUNC('week', NOW())`, [churchId])
    ]);

    res.json({
      success: true,
      data: {
        total_members: parseInt(members.rows[0].count),
        weekly_attendance: parseInt(attendance.rows[0].count),
        monthly_giving: parseFloat(giving.rows[0].total),
        weekly_volunteers: parseInt(volunteers.rows[0].count)
      }
    });
  } catch (err) { next(err); }
});

router.get('/upcoming-events', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      `SELECT e.*, COUNT(ea.id) as registered_count
       FROM events e LEFT JOIN event_attendance ea ON e.id = ea.event_id
       WHERE e.church_id = $1 AND e.start_datetime >= NOW() AND e.status = 'published'
       GROUP BY e.id ORDER BY e.start_datetime ASC LIMIT 5`,
      [req.user.church_id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

router.get('/giving-trend', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      `SELECT DATE_TRUNC('month', donation_date) as month, SUM(amount) as total
       FROM donations WHERE church_id = $1 AND donation_date >= NOW() - INTERVAL '12 months'
       GROUP BY DATE_TRUNC('month', donation_date) ORDER BY month ASC`,
      [req.user.church_id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

module.exports = router;