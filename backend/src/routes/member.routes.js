const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { query } = require('../database/connection');
const { authenticate, authorize } = require('../middleware/auth');

const memberSchema = Joi.object({
  first_name: Joi.string().min(1).max(100).required(),
  last_name: Joi.string().min(1).max(100).required(),
  email: Joi.string().email().allow(''),
  phone: Joi.string().allow(''),
  date_of_birth: Joi.date().allow(null),
  gender: Joi.string().valid('male', 'female', 'other', 'prefer_not_to_say').allow(''),
  marital_status: Joi.string().valid('single', 'married', 'divorced', 'widowed').allow(''),
  address: Joi.string().allow(''),
  city: Joi.string().allow(''),
  state: Joi.string().allow(''),
  zip_code: Joi.string().allow(''),
  membership_status: Joi.string().valid('visitor', 'member', 'active', 'inactive', 'deceased').default('visitor'),
  membership_date: Joi.date().allow(null),
  baptism_date: Joi.date().allow(null),
  emergency_contact_name: Joi.string().allow(''),
  emergency_contact_phone: Joi.string().allow(''),
  notes: Joi.string().allow('')
});

// GET /api/members
router.get('/', authenticate, async (req, res, next) => {
  try {
    const { search, status, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const churchId = req.user.church_id;

    let whereClause = 'WHERE church_id = $1';
    let params = [churchId];
    let paramCount = 1;

    if (search) {
      paramCount++;
      whereClause += ` AND (first_name ILIKE $${paramCount} OR last_name ILIKE $${paramCount} OR email ILIKE $${paramCount} OR phone ILIKE $${paramCount})`;
      params.push(`%${search}%`);
    }
    if (status) {
      paramCount++;
      whereClause += ` AND membership_status = $${paramCount}`;
      params.push(status);
    }

    const countResult = await query(`SELECT COUNT(*) FROM members ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count);

    params.push(parseInt(limit), offset);
    const result = await query(
      `SELECT id, first_name, last_name, email, phone, membership_status, membership_date, photo_url, created_at
       FROM members ${whereClause} ORDER BY created_at DESC LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`,
      params
    );

    res.json({
      success: true,
      data: result.rows,
      pagination: { page: parseInt(page), limit: parseInt(limit), total, totalPages: Math.ceil(total / parseInt(limit)) }
    });
  } catch (err) { next(err); }
});

// GET /api/members/:id
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      `SELECT m.*, 
        json_agg(DISTINCT jsonb_build_object('group_id', g.id, 'group_name', g.name, 'role', gm.role)) FILTER (WHERE g.id IS NOT NULL) as groups
       FROM members m
       LEFT JOIN group_members gm ON m.id = gm.member_id
       LEFT JOIN small_groups g ON gm.group_id = g.id
       WHERE m.id = $1 AND m.church_id = $2
       GROUP BY m.id`,
      [req.params.id, req.user.church_id]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Member not found' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// POST /api/members
router.post('/', authenticate, authorize('admin', 'pastor', 'staff'), async (req, res, next) => {
  try {
    const { error } = memberSchema.validate(req.body);
    if (error) return res.status(400).json({ success: false, message: error.details[0].message });

    const fields = Object.keys(req.body);
    const values = Object.values(req.body);
    const columns = fields.join(', ');
    const placeholders = fields.map((_, i) => `$${i + 2}`).join(', ');

    const result = await query(
      `INSERT INTO members (church_id, ${columns}) VALUES ($1, ${placeholders}) RETURNING *`,
      [req.user.church_id, ...values]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// PUT /api/members/:id
router.put('/:id', authenticate, authorize('admin', 'pastor', 'staff'), async (req, res, next) => {
  try {
    const fields = Object.keys(req.body);
    const values = Object.values(req.body);
    const setClause = fields.map((f, i) => `${f} = $${i + 2}`).join(', ');

    const result = await query(
      `UPDATE members SET ${setClause}, updated_at = NOW() WHERE id = $1 AND church_id = $${fields.length + 2} RETURNING *`,
      [req.params.id, ...values, req.user.church_id]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Member not found' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// DELETE /api/members/:id
router.delete('/:id', authenticate, authorize('admin', 'pastor'), async (req, res, next) => {
  try {
    const result = await query('DELETE FROM members WHERE id = $1 AND church_id = $2 RETURNING id', [req.params.id, req.user.church_id]);
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Member not found' });
    res.json({ success: true, message: 'Member deleted' });
  } catch (err) { next(err); }
});

module.exports = router;