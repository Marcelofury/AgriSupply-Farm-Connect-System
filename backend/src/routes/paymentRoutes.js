const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticate } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/errorMiddleware');
const { paymentValidators } = require('../utils/validators');

/**
 * @route   POST /api/v1/payments/initiate
 * @desc    Initiate payment for order
 * @access  Private
 */
router.post(
  '/initiate',
  authenticate,
  paymentValidators.initiate,
  handleValidation,
  paymentController.initiatePayment
);

/**
 * @route   GET /api/v1/payments/:orderId/status
 * @desc    Get payment status for order
 * @access  Private
 */
router.get('/:orderId/status', authenticate, paymentController.getPaymentStatus);

/**
 * @route   POST /api/v1/payments/mtn/callback
 * @desc    MTN Mobile Money callback
 * @access  Public (Webhook)
 */
router.post('/mtn/callback', paymentController.mtnCallback);

/**
 * @route   POST /api/v1/payments/airtel/callback
 * @desc    Airtel Money callback
 * @access  Public (Webhook)
 */
router.post('/airtel/callback', paymentController.airtelCallback);

/**
 * @route   POST /api/v1/payments/card/callback
 * @desc    Card payment callback (Flutterwave)
 * @access  Public (Webhook)
 */
router.post('/card/callback', paymentController.cardCallback);

/**
 * @route   GET /api/v1/payments/verify/:transactionId
 * @desc    Verify payment transaction
 * @access  Private
 */
router.get('/verify/:transactionId', authenticate, paymentController.verifyPayment);

/**
 * @route   POST /api/v1/payments/:orderId/retry
 * @desc    Retry failed payment
 * @access  Private
 */
router.post('/:orderId/retry', authenticate, paymentController.retryPayment);

/**
 * @route   GET /api/v1/payments/methods
 * @desc    Get available payment methods
 * @access  Public
 */
router.get('/methods', paymentController.getPaymentMethods);

/**
 * @route   POST /api/v1/payments/:orderId/refund
 * @desc    Process refund for order
 * @access  Private (Admin)
 */
router.post('/:orderId/refund', authenticate, paymentController.processRefund);

/**
 * @route   GET /api/v1/payments/history
 * @desc    Get payment history for current user
 * @access  Private
 */
router.get('/history', authenticate, paymentController.getPaymentHistory);

module.exports = router;
