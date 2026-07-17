const router = require('express').Router();
const controller = require('../controllers/telemetryController');
const { requireEsp32Token } = require('../middleware/auth');

router.post('/cart/telemetry', requireEsp32Token, controller.ingest);

module.exports = router;
