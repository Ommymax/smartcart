const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const env = require('../config/env');
const userModel = require('../models/userModel');
const cartModel = require('../models/cartModel');
const HttpError = require('../utils/httpError');

function signToken(user) {
  return jwt.sign({ sub: user.id, role: user.role }, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn
  });
}

async function register({ name, email, password, role = 'operator' }) {
  const existing = await userModel.findByEmail(email);
  if (existing) throw new HttpError(409, 'Email is already registered');
  const passwordHash = await bcrypt.hash(password, 12);
  const user = await userModel.createUser({ name, email, passwordHash, role });
  return { user, token: signToken(user) };
}

async function login({ email, password }) {
  const userWithPassword = await userModel.findByEmail(email);
  if (!userWithPassword) throw new HttpError(401, 'Invalid email or password');
  const ok = await bcrypt.compare(password, userWithPassword.password_hash);
  if (!ok) throw new HttpError(401, 'Invalid email or password');
  const { password_hash: _passwordHash, ...user } = userWithPassword;
  return { user, token: signToken(user) };
}

async function registerWithCart({ name, email, password, cart }) {
  if (!cart?.cartId || !cart?.cartName) {
    throw new HttpError(400, 'Cart ID and cart name are required');
  }

  const result = await register({ name, email, password, role: 'operator' });
  const savedCart = await cartModel.createCartForUser(cart, result.user.id);
  return { ...result, cart: savedCart };
}

module.exports = {
  register,
  login,
  registerWithCart
};
