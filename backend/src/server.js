const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const { pool } = require('./database/connection');
const errorHandler = require('./middleware/errorHandler');

const authRoutes = require('./routes/auth.routes');
const notificationRoutes = require('./routes/notification.routes');
const memberRoutes = require('./routes/member.routes');
const ministerRoutes = require('./routes/minister.routes');
const eventRoutes = require('./routes/event.routes');
const givingRoutes = require('./routes/giving.routes');
const volunteerRoutes = require('./routes/volunteer.routes');
const communicationRoutes = require('./routes/communication.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const sermonRoutes = require('./routes/sermon.routes');
const groupRoutes = require('./routes/group.routes');

const app = express();

app.use(helmet());
app.use(cors({ origin: process.env.FRONTEND_URL || '*', credentials: true }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Too many requests, please try again later.'
});
app.use('/api/', limiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT NOW()');
    res.json({ status: 'ok', database: 'connected' });
  } catch (err) {
    console.error('Health check DB error:', JSON.stringify({
      message: err && err.message,
      code: err && err.code,
      name: err && err.name
    }));
    res.status(503).json({ status: 'error', database: 'disconnected' });
  }
});

app.use('/api/auth', authRoutes);
app.use('/api/members', memberRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/ministers', ministerRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/giving', givingRoutes);
app.use('/api/volunteers', volunteerRoutes);
app.use('/api/communications', communicationRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/sermons', sermonRoutes);
app.use('/api/groups', groupRoutes);

app.use(errorHandler);
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`GraceHub API on port ${PORT}`);
});

module.exports = app;