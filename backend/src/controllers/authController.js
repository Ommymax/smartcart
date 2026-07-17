const authService = require('../services/authService');
const userModel = require('../models/userModel');
const asyncHandler = require('../utils/asyncHandler');

exports.register = asyncHandler(async (req, res) => {
  const result = await authService.register({ ...req.body, role: 'operator' });
  res.status(201).json(result);
});

exports.registerWithCart = asyncHandler(async (req, res) => {
  const result = await authService.registerWithCart(req.body);
  res.status(201).json(result);
});

exports.login = asyncHandler(async (req, res) => {
  const result = await authService.login(req.body);
  res.json(result);
});

exports.forgotPassword = asyncHandler(async (_req, res) => {
  res.json({ message: 'Password reset request accepted. Configure email delivery for production.' });
});

exports.resetPassword = asyncHandler(async (_req, res) => {
  res.json({ message: 'Password reset endpoint placeholder. Add signed reset tokens for production.' });
});

exports.me = asyncHandler(async (req, res) => {
  res.json({ user: req.user });
});

exports.users = asyncHandler(async (_req, res) => {
  res.json({ data: await userModel.listUsers() });
});
