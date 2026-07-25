const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { query } = require('../database/connection');

router.get('/series', authenticate, async (req, res, next) => {
  try {
    const result = await query(
      'SELECT * FROM sermon_series WHERE church_id = $1 ORDER BY start_date DESC',
      [req.user.church_id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

router.get('/', authenticate, async (req, res, next) => {
  try {
    const { series_id, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    let where = 'WHERE s.church_id = $1';
    let params = [req.user.church_id];
    let p = 1;

    if (series_id) { p++; where += ` AND s.series_id = $${p}`; params.push(series_id); }

    params.push(parseInt(limit), offset);
    const result = await query(
      `SELECT s.*, ss.title as series_title
       FROM sermons s
       LEFT JOIN sermon_series ss ON s.series_id = ss.id
       ${where} ORDER BY s.preached_date DESC LIMIT $${p + 1} OFFSET $${p + 2}`,
      params
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

module.exports = router;