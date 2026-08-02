const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { query } = require('../database/connection');

// GET /api/ministers
router.get('/', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      'SELECT * FROM ministers WHERE church_id = $1 ORDER BY display_order ASC, full_name ASC',
      [req.user.church_id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

// POST /api/ministers
router.post('/', authenticate, authorize('admin', 'pastor'), async (req, res, next) => {
  try {
    const { full_name, title, department, photo_url, bio, phone, email, display_order } = req.body;
    const result = await query(
      `INSERT INTO ministers (church_id, full_name, title, department, photo_url, bio, phone, email, display_order)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
      [req.user.church_id, full_name, title, department || null, photo_url || null, bio || null, phone || null, email || null, display_order || 0]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// PUT /api/ministers/:id
router.put('/:id', authenticate, authorize('admin', 'pastor'), async (req, res, next) => {
  try {
    const fields = Object.keys(req.body);
    const values = Object.values(req.body);
    const setClause = fields.map((f, i) => `${f} = $${i + 2}`).join(', ');

    const result = await query(
      `UPDATE ministers SET ${setClause} WHERE id = $1 AND church_id = $${fields.length + 2} RETURNING *`,
      [req.params.id, ...values, req.user.church_id]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Minister not found' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// DELETE /api/ministers/:id
router.delete('/:id', authenticate, authorize('admin', 'pastor'), async (req, res, next) => {
  try {
    const result = await query('DELETE FROM ministers WHERE id = $1 AND church_id = $2 RETURNING id', [req.params.id, req.user.church_id]);
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Minister not found' });
    res.json({ success: true, message: 'Minister deleted' });
  } catch (err) { next(err); }
});

module.exports = router;