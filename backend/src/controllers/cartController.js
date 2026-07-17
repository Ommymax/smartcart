const cartModel = require('../models/cartModel');
const telemetryModel = require('../models/telemetryModel');
const HttpError = require('../utils/httpError');
const asyncHandler = require('../utils/asyncHandler');

exports.list = asyncHandler(async (req, res) => {
  const data = await cartModel.listCarts({ assignedUserId: req.user.id, role: req.user.role });
  res.json({ data });
});

exports.get = asyncHandler(async (req, res) => {
  const cart = await cartModel.findByCartId(req.params.id);
  if (!cart) throw new HttpError(404, 'Cart not found');
  res.json({ data: cart });
});

exports.create = asyncHandler(async (req, res) => {
  const cart = await cartModel.createCart(req.body);
  res.status(201).json({ data: cart });
});

exports.createMine = asyncHandler(async (req, res) => {
  const cartId = req.body.cartId;
  if (!cartId) throw new HttpError(400, 'Cart ID is required');

  const existing = await cartModel.findByCartId(cartId);
  if (!existing) throw new HttpError(404, 'ID not found');

  const cart = await cartModel.assignCartToUser(cartId, req.user.id);
  res.status(201).json({ data: cart });
});

exports.update = asyncHandler(async (req, res) => {
  const cart = await cartModel.updateCart(req.params.id, req.body);
  if (!cart) throw new HttpError(404, 'Cart not found');
  res.json({ data: cart });
});

exports.remove = asyncHandler(async (req, res) => {
  const cart = await cartModel.deleteCart(req.params.id);
  if (!cart) throw new HttpError(404, 'Cart not found');
  res.json({ data: cart });
});

exports.latestTelemetry = asyncHandler(async (req, res) => {
  res.json({ data: await telemetryModel.latestTelemetry(req.params.id) });
});

exports.telemetryHistory = asyncHandler(async (req, res) => {
  const data = await telemetryModel.telemetryHistory(req.params.id, req.query);
  res.json({ data });
});

exports.status = asyncHandler(async (req, res) => {
  const latest = await telemetryModel.latestTelemetry(req.params.id);
  const online = latest ? Date.now() - new Date(latest.created_at).getTime() <= 30000 : false;
  res.json({ data: { cartId: req.params.id, online, latest } });
});
