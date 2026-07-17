const jwt = require('jsonwebtoken');
const env = require('../config/env');
const userModel = require('../models/userModel');
const HttpError = require('../utils/httpError');

async function requireAuth(req, _res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) throw new HttpError(401, 'Authentication token is required');

    const decoded = jwt.verify(token, env.jwtSecret);
    const user = await userModel.findById(decoded.sub);
    if (!user) throw new HttpError(401, 'User no longer exists');

    req.user = user;
    next();
  } catch (error) {
    next(error.statusCode ? error : new HttpError(401, 'Invalid or expired token'));
  }
}

function requireRole(...roles) {
  return (req, _res, next) => {
    if (!roles.includes(req.user.role)) {
      return next(new HttpError(403, 'You do not have permission to perform this action'));
    }
    next();
  };
}

function requireEsp32Token(req, _res, next) {
  const token = req.headers['x-api-token'];
  if (token !== env.esp32ApiToken) {
    return next(new HttpError(401, 'Invalid telemetry API token'));
  }
  next();
}

module.exports = {
  requireAuth,
  requireRole,
  requireEsp32Token
};
