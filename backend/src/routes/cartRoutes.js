const router = require('express').Router();
const controller = require('../controllers/cartController');
const { requireAuth, requireRole } = require('../middleware/auth');

router.get('/', requireAuth, controller.list);
router.post('/mine', requireAuth, controller.createMine);
router.get('/:id', requireAuth, controller.get);
router.post('/', requireAuth, requireRole('administrator'), controller.create);
router.put('/:id', requireAuth, requireRole('administrator'), controller.update);
router.delete('/:id', requireAuth, requireRole('administrator'), controller.remove);
router.get('/:id/telemetry/latest', requireAuth, controller.latestTelemetry);
router.get('/:id/telemetry/history', requireAuth, controller.telemetryHistory);
router.get('/:id/status', requireAuth, controller.status);

module.exports = router;
