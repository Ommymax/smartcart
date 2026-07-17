const analyticsService = require('../services/analyticsService');
const asyncHandler = require('../utils/asyncHandler');

exports.summary = asyncHandler(async (_req, res) => {
  res.json({ data: await analyticsService.summary() });
});

exports.cart = asyncHandler(async (req, res) => {
  res.json({ data: await analyticsService.cartAnalytics(req.params.id) });
});

exports.battery = asyncHandler(async (_req, res) => {
  res.json({ data: await analyticsService.batteryAnalytics() });
});

exports.sensors = asyncHandler(async (_req, res) => {
  res.json({ data: await analyticsService.sensorAnalytics() });
});
