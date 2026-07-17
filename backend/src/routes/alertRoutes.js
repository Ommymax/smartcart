const router = require('express').Router();
const controller = require('../controllers/alertController');
const { requireAuth } = require('../middleware/auth');

router.get('/', requireAuth, controller.list);
router.get('/:id', requireAuth, controller.get);
router.put('/:id/read', requireAuth, controller.markRead);
router.delete('/:id', requireAuth, controller.remove);

module.exports = router;
