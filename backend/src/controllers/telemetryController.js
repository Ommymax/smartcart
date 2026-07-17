const telemetryService = require('../services/telemetryService');
const asyncHandler = require('../utils/asyncHandler');

exports.ingest = asyncHandler(async (req, res) => {
  const packet = await telemetryService.ingestTelemetry(req.body, req.app.get('io'));
  res.status(201).json({ message: 'Telemetry accepted', data: packet });
});
