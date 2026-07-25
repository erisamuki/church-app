const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);
  if (err.code === '23505') {
    return res.status(409).json({ success: false, message: 'Duplicate entry.', field: err.detail });
  }
  if (err.code === '23503') {
    return res.status(400).json({ success: false, message: 'Referenced record does not exist.' });
  }
  if (err.code === '22P02') {
    return res.status(400).json({ success: false, message: 'Invalid input format.' });
  }
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({ success: false, message: 'Invalid token.' });
  }
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

module.exports = errorHandler;