const { z } = require('zod');
const cartModel = require('../models/cartModel');
const telemetryModel = require('../models/telemetryModel');
const alertService = require('./alertService');
const HttpError = require('../utils/httpError');

const telemetrySchema = z.object({
  cartId: z.string().min(1),
  powerStatus: z.string().min(1),
  motionStatus: z.string().min(1),
  stopReason: z.string().default('none'),
  batteryVoltage: z.number().nonnegative(),
  batteryPercentage: z.number().int().min(0).max(100),
  radioConnected: z.boolean(),
  internetConnected: z.boolean(),
  ultrasonic: z.object({
    front: z.object({ active: z.boolean(), distanceCm: z.number().nullable() }),
    left: z.object({ active: z.boolean(), distanceCm: z.number().nullable() }),
    right: z.object({ active: z.boolean(), distanceCm: z.number().nullable() })
  }),
  rssi: z.object({
    left: z.number().int().nullable(),
    right: z.number().int().nullable()
  }),
  location: z.object({
    available: z.boolean(),
    source: z.string().optional(),
    latitude: z.number().nullable(),
    longitude: z.number().nullable()
  }),
  uptimeMs: z.number().int().nonnegative()
});

async function ingestTelemetry(rawPayload, io) {
  const payload = telemetrySchema.parse(rawPayload);
  const cart = await cartModel.findByCartId(payload.cartId);
  if (!cart) throw new HttpError(404, `Unknown cart ID: ${payload.cartId}`);
  if (cart.status === 'disabled') throw new HttpError(403, 'Cart is disabled');

  const telemetry = await telemetryModel.insertTelemetry(payload);
  const alerts = await alertService.createTelemetryAlerts(payload);

  const packet = { cartId: payload.cartId, telemetry, alerts };
  io.emit('telemetry:new', packet);
  io.to(`cart:${payload.cartId}`).emit('cart:telemetry', packet);
  if (alerts.length) io.emit('alerts:new', alerts);

  return packet;
}

module.exports = {
  ingestTelemetry,
  telemetrySchema
};
