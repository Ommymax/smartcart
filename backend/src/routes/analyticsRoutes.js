const router = require('express').Router();
const controller = require('../controllers/analyticsController');
const { requireAuth } = require('../middleware/auth');

router.get('/summary', requireAuth, controller.summary);
router.get('/cart/:id', requireAuth, controller.cart);
router.get('/battery', requireAuth, controller.battery);
router.get('/sensors', requireAuth, controller.sensors);

module.exports = router;
