const jwt = require('jsonwebtoken');
const env = require('../config/env');

function registerSockets(io) {
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error('Socket auth token required'));
    try {
      socket.user = jwt.verify(token, env.jwtSecret);
      next();
    } catch (_error) {
      next(new Error('Invalid socket token'));
    }
  });

  io.on('connection', (socket) => {
    socket.on('cart:join', (cartId) => socket.join(`cart:${cartId}`));
    socket.on('cart:leave', (cartId) => socket.leave(`cart:${cartId}`));
  });
}

module.exports = registerSockets;
