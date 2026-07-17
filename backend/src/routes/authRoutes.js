const router = require('express').Router();
const controller = require('../controllers/authController');
const { requireAuth, requireRole } = require('../middleware/auth');

router.post('/register', controller.register);
router.post('/register-with-cart', controller.registerWithCart);
router.post('/login', controller.login);
router.post('/forgot-password', controller.forgotPassword);
router.post('/reset-password', controller.resetPassword);
router.get('/me', requireAuth, controller.me);
router.get('/users', requireAuth, requireRole('administrator'), controller.users);

module.exports = router;
