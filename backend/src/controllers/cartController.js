const cartModel = require('../models/cartModel');
const commandModel = require('../models/commandModel');
const telemetryModel = require('../models/telemetryModel');
const HttpError = require('../utils/httpError');
const asyncHandler = require('../utils/asyncHandler');

const allowedCommands = new Set(['auto', 'forward', 'left', 'right', 'stop', 'emergency_stop']);

exports.list = asyncHandler(async (req, res) => {
  const data = await cartModel.listCarts({ assignedUserId: req.user.id, role: req.user.role });
  res.json({ data });
});

exports.get = asyncHandler(async (req, res) => {
  const cart = await cartModel.findByCartId(req.params.id);
  if (!cart) throw new HttpError(404, 'Device not found');
  res.json({ data: cart });
});

exports.create = asyncHandler(async (req, res) => {
  const cart = await cartModel.createCart(req.body);
  res.status(201).json({ data: cart });
});

exports.createMine = asyncHandler(async (req, res) => {
  const cartId = String(req.body.cartId || '').trim();
  const cartName = String(req.body.cartName || cartId).trim();
  if (!cartId) throw new HttpError(400, 'Device ID is required');
  if (!cartName) throw new HttpError(400, 'Device name is required');

  const existing = await cartModel.findByCartId(cartId);
  const cart = existing
    ? await cartModel.assignCartToUser(cartId, req.user.id)
    : await cartModel.createCartForUser({ cartId, cartName }, req.user.id);
  res.status(201).json({ data: cart });
});

exports.update = asyncHandler(async (req, res) => {
  const cart = await cartModel.updateCart(req.params.id, req.body);
  if (!cart) throw new HttpError(404, 'Device not found');
  res.json({ data: cart });
});

exports.remove = asyncHandler(async (req, res) => {
  const cart = await cartModel.deleteCart(req.params.id);
  if (!cart) throw new HttpError(404, 'Device not found');
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

exports.createCommand = asyncHandler(async (req, res) => {
  const cart = await cartModel.findAccessibleCart(req.params.id, req.user);
  if (!cart) throw new HttpError(404, 'Device not found');
  if (cart.status === 'disabled') throw new HttpError(403, 'Device is disabled');

  const command = String(req.body.command || '').trim();
  if (!allowedCommands.has(command)) throw new HttpError(400, 'Invalid control command');

  const parsedSpeed = Number.parseInt(req.body.speed ?? 90, 10);
  const parsedDuration = Number.parseInt(req.body.durationMs ?? 700, 10);
  const speed = Math.max(0, Math.min(255, Number.isNaN(parsedSpeed) ? 90 : parsedSpeed));
  const durationMs = Math.max(100, Math.min(10000, Number.isNaN(parsedDuration) ? 700 : parsedDuration));

  const data = await commandModel.createCommand({
    cartId: cart.cart_id,
    command,
    speed,
    durationMs,
    userId: req.user.id
  });

  req.app.get('io').to(`cart:${cart.cart_id}`).emit('cart:command', data);
  res.status(201).json({ data });
});

exports.latestCommand = asyncHandler(async (req, res) => {
  const cart = await cartModel.findByCartId(req.params.id);
  if (!cart) throw new HttpError(404, 'Unknown cart ID');
  if (cart.status === 'disabled') throw new HttpError(403, 'Device is disabled');

  const command = await commandModel.latestCommand(req.params.id);
  if (!command) {
    return res.json({
      data: {
        cartId: req.params.id,
        command: 'none',
        speed: 0,
        durationMs: 0
      }
    });
  }

  res.json({
    data: {
      id: command.id,
      cartId: command.cart_id,
      command: command.command,
      speed: command.speed,
      durationMs: command.duration_ms,
      createdAt: command.created_at,
      expiresAt: command.expires_at
    }
  });
});
