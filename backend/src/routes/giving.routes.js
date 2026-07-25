const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { query } = require('../database/connection');

router.get('/categories', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      'SELECT * FROM giving_categories WHERE church_id = $1 AND is_active = true ORDER BY name',
      [req.user.church_id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

router.get('/', authenticate, async (req, res, next) => {
  try {
    const { page = 1, limit = 20, member_id, category_id } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    let where = 'WHERE d.church_id = $1';
    let params = [req.user.church_id];
    let p = 1;

    if (member_id) { p++; where += ` AND d.member_id = $${p}`; params.push(member_id); }
    if (category_id) { p++; where += ` AND d.category_id = $${p}`; params.push(category_id); }

    params.push(parseInt(limit), offset);
    const result = await query(
      `SELECT d.*, m.first_name, m.last_name, c.name as category_name, c.color
       FROM donations d
       LEFT JOIN members m ON d.member_id = m.id
       LEFT JOIN giving_categories c ON d.category_id = c.id
       ${where} ORDER BY d.donation_date DESC LIMIT $${p + 1} OFFSET $${p + 2}`,
      params
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

router.post('/', authenticate, authorize('admin', 'pastor', 'staff'), async (req, res, next) => {
  try {
    const { member_id, category_id, amount, payment_method, donation_date, notes } = req.body;
    const result = await query(
      `INSERT INTO donations (church_id, member_id, category_id, amount, payment_method, donation_date, notes, recorded_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [req.user.church_id, member_id, category_id, amount, payment_method, donation_date, notes, req.user.id]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

module.exports = router;