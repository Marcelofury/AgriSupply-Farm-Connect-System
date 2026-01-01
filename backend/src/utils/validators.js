const { body, param, query } = require('express-validator');
const constants = require('../config/constants');

// Auth validators
const authValidators = {
  register: [
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Please provide a valid email'),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters')
      .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      .withMessage('Password must contain at least one lowercase, one uppercase, and one number'),
    body('fullName')
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Full name must be between 2 and 100 characters'),
    body('role')
      .optional()
      .isIn(constants.userRoles)
      .withMessage('Invalid role'),
    body('phone')
      .optional()
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
  ],
  
  login: [
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Please provide a valid email'),
    body('password')
      .notEmpty()
      .withMessage('Password is required'),
  ],
  
  phoneOtp: [
    body('phone')
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
  ],
  
  verifyOtp: [
    body('phone')
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
    body('otp')
      .isLength({ min: 6, max: 6 })
      .isNumeric()
      .withMessage('OTP must be 6 digits'),
  ],
  
  resetPassword: [
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Please provide a valid email'),
  ],
  
  updatePassword: [
    body('currentPassword')
      .notEmpty()
      .withMessage('Current password is required'),
    body('newPassword')
      .isLength({ min: 8 })
      .withMessage('New password must be at least 8 characters')
      .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      .withMessage('Password must contain at least one lowercase, one uppercase, and one number'),
  ],
};

// User validators
const userValidators = {
  updateProfile: [
    body('fullName')
      .optional()
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Full name must be between 2 and 100 characters'),
    body('phone')
      .optional()
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
    body('region')
      .optional()
      .isIn(constants.uganda.regions)
      .withMessage('Invalid region'),
    body('bio')
      .optional()
      .isLength({ max: 500 })
      .withMessage('Bio must be less than 500 characters'),
  ],
  
  updateAddress: [
    body('region')
      .isIn(constants.uganda.regions)
      .withMessage('Invalid region'),
    body('district')
      .notEmpty()
      .withMessage('District is required'),
    body('address')
      .notEmpty()
      .isLength({ min: 5, max: 200 })
      .withMessage('Address must be between 5 and 200 characters'),
  ],
};

// Product validators
const productValidators = {
  create: [
    body('name')
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Product name must be between 2 and 100 characters'),
    body('description')
      .optional()
      .isLength({ max: 2000 })
      .withMessage('Description must be less than 2000 characters'),
    body('category')
      .isIn(constants.productCategories.map(c => c.id))
      .withMessage('Invalid category'),
    body('price')
      .isFloat({ min: 0 })
      .withMessage('Price must be a positive number'),
    body('unit')
      .isIn(['kg', 'g', 'piece', 'bunch', 'liter', 'dozen', 'bag', 'crate'])
      .withMessage('Invalid unit'),
    body('quantity')
      .isInt({ min: 0 })
      .withMessage('Quantity must be a non-negative integer'),
    body('isOrganic')
      .optional()
      .isBoolean()
      .withMessage('isOrganic must be a boolean'),
  ],
  
  update: [
    body('name')
      .optional()
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Product name must be between 2 and 100 characters'),
    body('description')
      .optional()
      .isLength({ max: 2000 })
      .withMessage('Description must be less than 2000 characters'),
    body('category')
      .optional()
      .isIn(constants.productCategories.map(c => c.id))
      .withMessage('Invalid category'),
    body('price')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Price must be a positive number'),
    body('quantity')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Quantity must be a non-negative integer'),
  ],
  
  id: [
    param('id')
      .isUUID()
      .withMessage('Invalid product ID'),
  ],
  
  list: [
    query('page')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Page must be a positive integer'),
    query('limit')
      .optional()
      .isInt({ min: 1, max: 100 })
      .withMessage('Limit must be between 1 and 100'),
    query('category')
      .optional()
      .isIn(constants.productCategories.map(c => c.id))
      .withMessage('Invalid category'),
    query('region')
      .optional()
      .isIn(constants.uganda.regions)
      .withMessage('Invalid region'),
    query('minPrice')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Minimum price must be a positive number'),
    query('maxPrice')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Maximum price must be a positive number'),
  ],
  
  review: [
    body('rating')
      .isInt({ min: 1, max: 5 })
      .withMessage('Rating must be between 1 and 5'),
    body('comment')
      .optional()
      .isLength({ max: 1000 })
      .withMessage('Comment must be less than 1000 characters'),
  ],
};

// Order validators
const orderValidators = {
  create: [
    body('items')
      .isArray({ min: 1 })
      .withMessage('Order must have at least one item'),
    body('items.*.productId')
      .isUUID()
      .withMessage('Invalid product ID'),
    body('items.*.quantity')
      .isInt({ min: 1 })
      .withMessage('Quantity must be at least 1'),
    body('shippingAddress')
      .notEmpty()
      .withMessage('Shipping address is required'),
    body('shippingAddress.region')
      .isIn(constants.uganda.regions)
      .withMessage('Invalid region'),
    body('shippingAddress.district')
      .notEmpty()
      .withMessage('District is required'),
    body('shippingAddress.address')
      .isLength({ min: 5, max: 200 })
      .withMessage('Address must be between 5 and 200 characters'),
    body('paymentMethod')
      .isIn(['mtn_mobile', 'airtel_money', 'card', 'cash_on_delivery'])
      .withMessage('Invalid payment method'),
  ],
  
  updateStatus: [
    body('status')
      .isIn(constants.orderStatuses)
      .withMessage('Invalid order status'),
    body('note')
      .optional()
      .isLength({ max: 500 })
      .withMessage('Note must be less than 500 characters'),
  ],
  
  id: [
    param('id')
      .isUUID()
      .withMessage('Invalid order ID'),
  ],
};

// Payment validators
const paymentValidators = {
  initiate: [
    body('orderId')
      .isUUID()
      .withMessage('Invalid order ID'),
    body('method')
      .isIn(['mtn_mobile', 'airtel_money', 'card', 'cash_on_delivery'])
      .withMessage('Invalid payment method'),
    body('phone')
      .optional()
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
  ],
  
  callback: [
    body('transactionId')
      .notEmpty()
      .withMessage('Transaction ID is required'),
    body('status')
      .isIn(['success', 'failed', 'pending'])
      .withMessage('Invalid status'),
  ],
};

// Notification validators
const notificationValidators = {
  id: [
    param('id')
      .isUUID()
      .withMessage('Invalid notification ID'),
  ],
  
  updatePreferences: [
    body('orderUpdates')
      .optional()
      .isBoolean()
      .withMessage('orderUpdates must be a boolean'),
    body('promotions')
      .optional()
      .isBoolean()
      .withMessage('promotions must be a boolean'),
    body('farmingTips')
      .optional()
      .isBoolean()
      .withMessage('farmingTips must be a boolean'),
    body('priceAlerts')
      .optional()
      .isBoolean()
      .withMessage('priceAlerts must be a boolean'),
  ],
};

// AI validators
const aiValidators = {
  chat: [
    body('message')
      .trim()
      .isLength({ min: 1, max: 2000 })
      .withMessage('Message must be between 1 and 2000 characters'),
    body('sessionId')
      .optional()
      .isUUID()
      .withMessage('Invalid session ID'),
  ],
  
  analyzeImage: [
    body('imageUrl')
      .isURL()
      .withMessage('Please provide a valid image URL'),
    body('question')
      .optional()
      .isLength({ max: 500 })
      .withMessage('Question must be less than 500 characters'),
  ],
};

// Admin validators
const adminValidators = {
  updateUser: [
    param('id')
      .isUUID()
      .withMessage('Invalid user ID'),
    body('role')
      .optional()
      .isIn(constants.userRoles)
      .withMessage('Invalid role'),
    body('isVerified')
      .optional()
      .isBoolean()
      .withMessage('isVerified must be a boolean'),
    body('isSuspended')
      .optional()
      .isBoolean()
      .withMessage('isSuspended must be a boolean'),
  ],
  
  userList: [
    query('role')
      .optional()
      .isIn(constants.userRoles)
      .withMessage('Invalid role'),
    query('region')
      .optional()
      .isIn(constants.uganda.regions)
      .withMessage('Invalid region'),
    query('isVerified')
      .optional()
      .isBoolean()
      .withMessage('isVerified must be a boolean'),
  ],
};

module.exports = {
  authValidators,
  userValidators,
  productValidators,
  orderValidators,
  paymentValidators,
  notificationValidators,
  aiValidators,
  adminValidators,
};
