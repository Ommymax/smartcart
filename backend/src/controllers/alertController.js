const alertModel = require('../models/alertModel');
const HttpError = require('../utils/httpError');
const asyncHandler = require('../utils/asyncHandler');

exports.list = asyncHandler(async (req, res) => {
  res.json({ data: await alertModel.listAlerts(req.query, req.user) });
});

exports.get = asyncHandler(async (req, res) => {
  const alert = await alertModel.findAlert(req.params.id, req.user);
  if (!alert) throw new HttpError(404, 'Alert not found');
  res.json({ data: alert });
});

exports.markRead = asyncHandler(async (req, res) => {
  const alert = await alertModel.markRead(req.params.id, req.user);
  if (!alert) throw new HttpError(404, 'Alert not found');
  res.json({ data: alert });
});

exports.remove = asyncHandler(async (req, res) => {
  const alert = await alertModel.deleteAlert(req.params.id, req.user);
  if (!alert) throw new HttpError(404, 'Alert not found');
  res.json({ data: alert });
});

exports.clear = asyncHandler(async (req, res) => {
  const data = await alertModel.deleteAlerts(req.query, req.user);
  res.json({ data, deleted: data.length });
});
