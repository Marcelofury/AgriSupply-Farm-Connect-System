const axios = require('axios');
const logger = require('../utils/logger');
const { ApiError } = require('../middleware/errorMiddleware');

/**
 * Relworx Payment Gateway Service
 * Handles mobile money payments for MTN & Airtel Uganda via Relworx API
 */

const RELWORX_API_URL = process.env.RELWORX_API_URL || 'https://payments.relworx.com/api';
const RELWORX_API_KEY = process.env.RELWORX_API_KEY;
const RELWORX_ACCOUNT_NO = process.env.RELWORX_ACCOUNT_NO;

// Axios instance with default Relworx headers
const relworxClient = axios.create({
  baseURL: RELWORX_API_URL,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/vnd.relworx.v2',
    'Authorization': `Bearer ${RELWORX_API_KEY}`,
  },
  timeout: 30000, // 30 seconds
});

/**
 * Validate mobile number before processing payment
 * Only works for Airtel and MTN Uganda numbers
 */
const validateMobileNumber = async (msisdn) => {
  try {
    const response = await relworxClient.post('/mobile-money/validate', {
      msisdn: msisdn,
    });

    if (response.data.success) {
      return {
        valid: true,
        customerName: response.data.customer_name,
        message: response.data.message,
      };
    }

    return {
      valid: false,
      message: 'Number validation failed',
    };
  } catch (error) {
    logger.warn('Relworx number validation failed:', error.response?.data || error.message);
    // Don't block payment if validation fails (might be network/service not supporting the number)
    return {
      valid: true, // Assume valid if service is down
      message: 'Validation service unavailable',
    };
  }
};

/**
 * Request payment from mobile money subscriber (Collection)
 * @param {Object} params - Payment parameters
 * @param {string} params.reference - Unique transaction reference (8-36 chars)
 * @param {string} params.msisdn - Phone number (internationally formatted: +256...)
 * @param {string} params.currency - Currency code (UGX, KES, TZS)
 * @param {number} params.amount - Amount to charge
 * @param {string} params.description - Payment description
 */
const requestPayment = async ({ reference, msisdn, currency = 'UGX', amount, description }) => {
  try {
    // Validate inputs
    if (!reference || reference.length < 8 || reference.length > 36) {
      throw new ApiError(400, 'Reference must be between 8 and 36 characters');
    }

    if (!msisdn || !msisdn.startsWith('+256')) {
      throw new ApiError(400, 'Invalid phone number format. Use international format: +256...');
    }

    if (!amount || amount <= 0) {
      throw new ApiError(400, 'Invalid amount');
    }

    logger.info(`Relworx: Requesting payment of ${currency} ${amount} from ${msisdn}`);

    const response = await relworxClient.post('/mobile-money/request-payment', {
      account_no: RELWORX_ACCOUNT_NO,
      reference: reference,
      msisdn: msisdn,
      currency: currency,
      amount: parseFloat(amount),
      description: description || 'AgriSupply payment',
    });

    if (response.data.success) {
      logger.info('Relworx payment request initiated:', response.data);
      return {
        success: true,
        message: response.data.message,
        internalReference: response.data.internal_reference,
        customerReference: reference,
        status: 'pending',
      };
    }

    throw new ApiError(400, response.data.message || 'Payment request failed');
  } catch (error) {
    if (error.response?.status === 429) {
      // Rate limit exceeded (5 requests per 10 minutes per msisdn)
      throw new ApiError(429, 'Too many payment requests. Please try again in a few minutes.');
    }

    logger.error('Relworx payment request error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || error.message || 'Payment initiation failed'
    );
  }
};

/**
 * Send payment to mobile money subscriber (Disbursement)
 * @param {Object} params - Payment parameters  
 * @param {string} params.reference - Unique transaction reference (8-36 chars)
 * @param {string} params.msisdn - Recipient phone number
 * @param {string} params.currency - Currency code (UGX, KES, TZS)
 * @param {number} params.amount - Amount to send
 * @param {string} params.description - Payment description
 */
const sendPayment = async ({ reference, msisdn, currency = 'UGX', amount, description }) => {
  try {
    logger.info(`Relworx: Sending payment of ${currency} ${amount} to ${msisdn}`);

    const response = await relworxClient.post('/mobile-money/send-payment', {
      account_no: RELWORX_ACCOUNT_NO,
      reference: reference,
      msisdn: msisdn,
      currency: currency,
      amount: parseFloat(amount),
      description: description || 'AgriSupply payout',
    });

    if (response.data.success) {
      logger.info('Relworx payment send initiated:', response.data);
      return {
        success: true,
        message: response.data.message,
        internalReference: response.data.internal_reference,
        customerReference: reference,
        status: 'pending',
      };
    }

    throw new ApiError(400, response.data.message || 'Payment send failed');
  } catch (error) {
    logger.error('Relworx payment send error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || error.message || 'Payment send failed'
    );
  }
};

/**
 * Check transaction status
 * @param {string} internalReference - Relworx internal reference OR customer reference
 */
const checkRequestStatus = async (internalReference) => {
  try {
    const response = await relworxClient.get('/mobile-money/check-request-status', {
      params: {
        internal_reference: internalReference,
        account_no: RELWORX_ACCOUNT_NO,
      },
    });

    if (response.data.success) {
      const data = response.data;
      return {
        success: true,
        status: data.status, // 'success', 'pending', 'failed'
        requestStatus: data.request_status,
        message: data.message,
        customerReference: data.customer_reference,
        internalReference: data.internal_reference,
        msisdn: data.msisdn,
        amount: data.amount,
        currency: data.currency,
        provider: data.provider,
        charge: data.charge,
        providerTransactionId: data.provider_transaction_id,
        completedAt: data.completed_at,
      };
    }

    return {
      success: false,
      status: 'unknown',
      message: 'Status check failed',
    };
  } catch (error) {
    logger.error('Relworx status check error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || 'Status check failed'
    );
  }
};

/**
 * Check wallet balance
 * @param {string} currency - Currency code (UGX, KES, TZS)
 */
const checkWalletBalance = async (currency = 'UGX') => {
  try {
    const response = await relworxClient.get('/mobile-money/check-wallet-balance', {
      params: {
        account_no: RELWORX_ACCOUNT_NO,
        currency: currency,
      },
    });

    if (response.data.success) {
      return {
        success: true,
        balance: response.data.balance,
        currency: currency,
      };
    }

    return {
      success: false,
      message: 'Balance check failed',
    };
  } catch (error) {
    logger.error('Relworx balance check error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || 'Balance check failed'
    );
  }
};

/**
 * Get transaction history (last 30 days, max 1000 transactions)
 */
const getTransactionHistory = async () => {
  try {
    const response = await relworxClient.get('/payment-requests/transactions', {
      params: {
        account_no: RELWORX_ACCOUNT_NO,
      },
    });

    if (response.data.success) {
      return {
        success: true,
        transactions: response.data.transactions,
      };
    }

    return {
      success: false,
      transactions: [],
    };
  } catch (error) {
    logger.error('Relworx transaction history error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || 'Failed to fetch transaction history'
    );
  }
};

/**
 * Format phone number to international format (+256...)
 */
const formatPhoneNumber = (phone) => {
  if (!phone) return null;

  // Remove spaces, dashes, parentheses
  let cleaned = phone.replace(/[\s\-()]/g, '');

  // If starts with 0, replace with +256
  if (cleaned.startsWith('0')) {
    cleaned = '+256' + cleaned.substring(1);
  }

  // If starts with 256, add +
  if (cleaned.startsWith('256') && !cleaned.startsWith('+')) {
    cleaned = '+' + cleaned;
  }

  // Validate format
  if (!cleaned.startsWith('+256') || cleaned.length !== 13) {
    return null;
  }

  return cleaned;
};

/**
 * Determine mobile money provider from phone number
 */
const getProvider = (phone) => {
  const formatted = formatPhoneNumber(phone);
  if (!formatted) return null;

  const digits = formatted.substring(4, 6); // Get first 2 digits after +256

  // MTN Uganda: 77, 78, 76
  if (['77', '78', '76'].includes(digits)) {
    return 'MTN_UGANDA';
  }

  // Airtel Uganda: 70, 75, 74
  if (['70', '75', '74'].includes(digits)) {
    return 'AIRTEL_UGANDA';
  }

  return 'UNKNOWN';
};

module.exports = {
  validateMobileNumber,
  requestPayment,
  sendPayment,
  checkRequestStatus,
  checkWalletBalance,
  getTransactionHistory,
  formatPhoneNumber,
  getProvider,
};
