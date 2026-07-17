const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const env = require('./config/env');
const errorHandler = require('./middleware/errorHandler');

const app = express();

app.use(helmet());
app.use(cors({ origin: env.corsOrigin.includes('*') ? '*' : env.corsOrigin }));
app.use(express.json({ limit: '1mb' }));
app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));
app.use(rateLimit({ windowMs: env.rateLimitWindowMs, limit: env.rateLimitMax }));

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'smartcart-backend' }));

app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/carts', require('./routes/cartRoutes'));
app.use('/api', require('./routes/telemetryRoutes'));
app.use('/api/alerts', require('./routes/alertRoutes'));
app.use('/api/analytics', require('./routes/analyticsRoutes'));

app.use((_req, res) => res.status(404).json({ message: 'Route not found' }));
app.use(errorHandler);

module.exports = app;
