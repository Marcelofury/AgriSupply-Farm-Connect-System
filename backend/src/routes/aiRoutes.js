const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');
const { authenticate, requirePremium } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/errorMiddleware');
const { uploadSingle } = require('../middleware/uploadMiddleware');
const { aiValidators } = require('../utils/validators');

/**
 * @route   POST /api/v1/ai/chat
 * @desc    Send message to AI assistant
 * @access  Private (Premium)
 */
router.post(
  '/chat',
  authenticate,
  requirePremium,
  aiValidators.chat,
  handleValidation,
  aiController.chat
);

/**
 * @route   POST /api/v1/ai/analyze-image
 * @desc    Analyze crop/plant image
 * @access  Private (Premium)
 */
router.post(
  '/analyze-image',
  authenticate,
  requirePremium,
  uploadSingle('image'),
  aiController.analyzeImage
);

/**
 * @route   GET /api/v1/ai/sessions
 * @desc    Get user's chat sessions
 * @access  Private (Premium)
 */
router.get('/sessions', authenticate, requirePremium, aiController.getChatSessions);

/**
 * @route   GET /api/v1/ai/sessions/:sessionId
 * @desc    Get chat session by ID
 * @access  Private (Premium)
 */
router.get('/sessions/:sessionId', authenticate, requirePremium, aiController.getChatSession);

/**
 * @route   DELETE /api/v1/ai/sessions/:sessionId
 * @desc    Delete chat session
 * @access  Private (Premium)
 */
router.delete('/sessions/:sessionId', authenticate, requirePremium, aiController.deleteChatSession);

/**
 * @route   POST /api/v1/ai/crop-analysis
 * @desc    Get detailed crop analysis
 * @access  Private (Premium)
 */
router.post('/crop-analysis', authenticate, requirePremium, aiController.getCropAnalysis);

/**
 * @route   GET /api/v1/ai/farming-tips
 * @desc    Get personalized farming tips
 * @access  Private (Premium)
 */
router.get('/farming-tips', authenticate, requirePremium, aiController.getFarmingTips);

/**
 * @route   GET /api/v1/ai/market-predictions
 * @desc    Get market predictions for crops
 * @access  Private (Premium)
 */
router.get('/market-predictions', authenticate, requirePremium, aiController.getMarketPredictions);

/**
 * @route   GET /api/v1/ai/weather-recommendations
 * @desc    Get weather-based farming recommendations
 * @access  Private (Premium)
 */
router.get('/weather-recommendations', authenticate, requirePremium, aiController.getWeatherRecommendations);

/**
 * @route   POST /api/v1/ai/pest-identification
 * @desc    Identify pests from image
 * @access  Private (Premium)
 */
router.post(
  '/pest-identification',
  authenticate,
  requirePremium,
  uploadSingle('image'),
  aiController.identifyPest
);

/**
 * @route   POST /api/v1/ai/disease-diagnosis
 * @desc    Diagnose plant disease from image
 * @access  Private (Premium)
 */
router.post(
  '/disease-diagnosis',
  authenticate,
  requirePremium,
  uploadSingle('image'),
  aiController.diagnosePlantDisease
);

/**
 * @route   GET /api/v1/ai/usage
 * @desc    Get AI usage statistics
 * @access  Private (Premium)
 */
router.get('/usage', authenticate, requirePremium, aiController.getUsageStats);

module.exports = router;
