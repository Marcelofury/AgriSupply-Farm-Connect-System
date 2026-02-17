const axios = require('axios');
const { supabase } = require('../config/supabase');
const { ApiError, asyncHandler } = require('../middleware/errorMiddleware');
const { formatPhoneNumber, getMobileMoneyProvider, generateOrderNumber } = require('../utils/helpers');
const logger = require('../utils/logger');
const relworxService = require('../services/relworxService');

// Payment provider configurations
const MTN_API_URL = process.env.MTN_ENVIRONMENT === 'production'
  ? 'https://proxy.momoapi.mtn.com'
  : 'https://sandbox.momodeveloper.mtn.com';

const AIRTEL_API_URL = process.env.AIRTEL_ENVIRONMENT === 'production'
  ? 'https://openapi.airtel.africa'
  : 'https://openapiuat.airtel.africa';

const FLUTTERWAVE_API_URL = 'https://api.flutterwave.com/v3';

/**
 * @desc    Initiate payment for order
 * @route   POST /api/v1/payments/initiate
 */
const initiatePayment = asyncHandler(async (req, res) => {
  const { orderId, method, phone } = req.body;
  const userId = req.user.id;

  // Get order
  const { data: order } = await supabase
    .from('orders')
    .select('*')
    .eq('id', orderId)
    .eq('buyer_id', userId)
    .single();

  if (!order) {
    throw new ApiError(404, 'Order not found');
  }

  if (order.payment_status === 'completed') {
    throw new ApiError(400, 'Order already paid');
  }

  let paymentResult;
  const transactionRef = `TXN-${generateOrderNumber()}`;

  switch (method) {
    case 'relworx_mobile': // New unified mobile money via Relworx
      paymentResult = await initiateRelworxPayment(order, phone, transactionRef);
      break;
    case 'mtn_mobile':
      paymentResult = await initiateMTNPayment(order, phone, transactionRef);
      break;
    case 'airtel_money':
      paymentResult = await initiateAirtelPayment(order, phone, transactionRef);
      break;
    case 'card':
      paymentResult = await initiateCardPayment(order, transactionRef, req.user.email);
      break;
    case 'cash_on_delivery':
      paymentResult = await initiateCODPayment(order, transactionRef);
      break;
    default:
      throw new ApiError(400, 'Invalid payment method');
  }

  // Create payment record
  const { error: paymentError } = await supabase.from('payments').insert({
    order_id: orderId,
    user_id: userId,
    amount: order.total,
    method,
    transaction_ref: transactionRef,
    status: paymentResult.status,
    provider_reference: paymentResult.providerRef,
    phone: formatPhoneNumber(phone),
    created_at: new Date().toISOString(),
  });

  if (paymentError) {
    logger.error('Create payment record error:', paymentError);
  }

  // Update order payment status
  await supabase
    .from('orders')
    .update({
      payment_status: paymentResult.status === 'completed' ? 'completed' : 'processing',
      payment_method: method,
      updated_at: new Date().toISOString(),
    })
    .eq('id', orderId);

  res.json({
    success: true,
    message: paymentResult.message,
    data: {
      transactionRef,
      status: paymentResult.status,
      providerRef: paymentResult.providerRef,
      paymentUrl: paymentResult.paymentUrl,
    },
  });
});

/**
 * Initiate Relworx Mobile Money payment (MTN & Airtel Uganda)
 */
const initiateRelworxPayment = async (order, phone, transactionRef) => {
  const formattedPhone = relworxService.formatPhoneNumber(phone);
  
  if (!formattedPhone) {
    throw new ApiError(400, 'Invalid phone number format. Use: +256... or 0...');
  }

  const provider = relworxService.getProvider(phone);
  if (provider === 'UNKNOWN') {
    throw new ApiError(400, 'Phone number must be MTN (77/78/76) or Airtel (70/75/74) Uganda');
  }

  try {
    // Optional: Validate phone number before payment
    const validation = await relworxService.validateMobileNumber(formattedPhone);
    logger.info(`Phone validation result for ${formattedPhone}:`, validation);

    // Request payment
    const result = await relworxService.requestPayment({
      reference: transactionRef,
      msisdn: formattedPhone,
      currency: 'UGX',
      amount: order.total,
      description: `AgriSupply Order #${order.order_number}`,
    });

    return {
      status: 'pending',
      message: result.message || 'Payment request sent. Please approve on your phone.',
      providerRef: result.internalReference,
      provider: provider,
    };
  } catch (error) {
    logger.error('Relworx payment error:', error.message);
    throw error; // Re-throw ApiError from service
  }
};

/**
 * Initiate MTN Mobile Money payment
 */
const initiateMTNPayment = async (order, phone, transactionRef) => {
  const formattedPhone = formatPhoneNumber(phone);
  
  if (!formattedPhone || getMobileMoneyProvider(phone) !== 'mtn') {
    throw new ApiError(400, 'Invalid MTN phone number');
  }

  try {
    // Get access token
    const tokenResponse = await axios.post(
      `${MTN_API_URL}/collection/token/`,
      {},
      {
        headers: {
          'Authorization': `Basic ${Buffer.from(`${process.env.MTN_API_KEY}:${process.env.MTN_API_SECRET}`).toString('base64')}`,
          'Ocp-Apim-Subscription-Key': process.env.MTN_SUBSCRIPTION_KEY,
        },
      }
    );

    const accessToken = tokenResponse.data.access_token;

    // Request payment
    const paymentResponse = await axios.post(
      `${MTN_API_URL}/collection/v1_0/requesttopay`,
      {
        amount: order.total.toString(),
        currency: 'UGX',
        externalId: transactionRef,
        payer: {
          partyIdType: 'MSISDN',
          partyId: formattedPhone.replace('+', ''),
        },
        payerMessage: `Payment for AgriSupply Order #${order.order_number}`,
        payeeNote: `Order #${order.order_number}`,
      },
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'X-Reference-Id': transactionRef,
          'X-Target-Environment': process.env.MTN_ENVIRONMENT || 'sandbox',
          'Ocp-Apim-Subscription-Key': process.env.MTN_SUBSCRIPTION_KEY,
          'Content-Type': 'application/json',
        },
      }
    );

    return {
      status: 'pending',
      message: 'Payment request sent. Please approve on your phone.',
      providerRef: transactionRef,
    };
  } catch (error) {
    logger.error('MTN payment error:', error.response?.data || error.message);
    throw new ApiError(400, 'MTN payment initiation failed');
  }
};

/**
 * Initiate Airtel Money payment
 */
const initiateAirtelPayment = async (order, phone, transactionRef) => {
  const formattedPhone = formatPhoneNumber(phone);
  
  if (!formattedPhone || getMobileMoneyProvider(phone) !== 'airtel') {
    throw new ApiError(400, 'Invalid Airtel phone number');
  }

  try {
    // Get access token
    const tokenResponse = await axios.post(
      `${AIRTEL_API_URL}/auth/oauth2/token`,
      {
        client_id: process.env.AIRTEL_API_KEY,
        client_secret: process.env.AIRTEL_API_SECRET,
        grant_type: 'client_credentials',
      },
      {
        headers: { 'Content-Type': 'application/json' },
      }
    );

    const accessToken = tokenResponse.data.access_token;

    // Request payment
    const paymentResponse = await axios.post(
      `${AIRTEL_API_URL}/merchant/v1/payments/`,
      {
        reference: transactionRef,
        subscriber: {
          country: 'UG',
          currency: 'UGX',
          msisdn: formattedPhone.replace('+256', ''),
        },
        transaction: {
          amount: order.total,
          country: 'UG',
          currency: 'UGX',
          id: transactionRef,
        },
      },
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
          'X-Country': 'UG',
          'X-Currency': 'UGX',
        },
      }
    );

    return {
      status: 'pending',
      message: 'Payment request sent. Please approve on your phone.',
      providerRef: paymentResponse.data.data?.transaction?.id || transactionRef,
    };
  } catch (error) {
    logger.error('Airtel payment error:', error.response?.data || error.message);
    throw new ApiError(400, 'Airtel payment initiation failed');
  }
};

/**
 * Initiate card payment via Flutterwave
 */
const initiateCardPayment = async (order, transactionRef, email) => {
  try {
    const response = await axios.post(
      `${FLUTTERWAVE_API_URL}/payments`,
      {
        tx_ref: transactionRef,
        amount: order.total,
        currency: 'UGX',
        redirect_url: `${process.env.FRONTEND_URL}/payment/callback`,
        payment_options: 'card',
        customer: {
          email,
          name: order.shipping_address?.name || 'Customer',
          phonenumber: order.shipping_address?.phone,
        },
        customizations: {
          title: 'AgriSupply',
          description: `Payment for Order #${order.order_number}`,
          logo: 'https://agrisupply.ug/logo.png',
        },
        meta: {
          order_id: order.id,
          order_number: order.order_number,
        },
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.FLUTTERWAVE_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    return {
      status: 'pending',
      message: 'Redirect to payment page',
      providerRef: response.data.data.flw_ref,
      paymentUrl: response.data.data.link,
    };
  } catch (error) {
    logger.error('Card payment error:', error.response?.data || error.message);
    throw new ApiError(400, 'Card payment initiation failed');
  }
};

/**
 * Initiate Cash on Delivery
 */
const initiateCODPayment = async (order, transactionRef) => {
  return {
    status: 'pending',
    message: 'Cash on delivery selected. Pay when you receive your order.',
    providerRef: transactionRef,
  };
};

/**
 * @desc    Get payment status for order
 * @route   GET /api/v1/payments/:orderId/status
 */
const getPaymentStatus = asyncHandler(async (req, res) => {
  const { orderId } = req.params;
  const userId = req.user.id;

  const { data: payment } = await supabase
    .from('payments')
    .select('*')
    .eq('order_id', orderId)
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  if (!payment) {
    throw new ApiError(404, 'Payment not found');
  }

  res.json({
    success: true,
    data: payment,
  });
});

/**
 * @desc    MTN Mobile Money callback
 * @route   POST /api/v1/payments/mtn/callback
 */
const mtnCallback = asyncHandler(async (req, res) => {
  const { externalId, status, financialTransactionId } = req.body;

  logger.info('MTN callback received:', req.body);

  // Update payment record
  const paymentStatus = status === 'SUCCESSFUL' ? 'completed' : 'failed';

  const { data: payment } = await supabase
    .from('payments')
    .update({
      status: paymentStatus,
      provider_reference: financialTransactionId,
      updated_at: new Date().toISOString(),
    })
    .eq('transaction_ref', externalId)
    .select()
    .single();

  if (payment) {
    // Update order payment status
    await supabase
      .from('orders')
      .update({
        payment_status: paymentStatus,
        updated_at: new Date().toISOString(),
      })
      .eq('id', payment.order_id);

    // Notify user
    const { data: order } = await supabase
      .from('orders')
      .select('buyer_id, order_number')
      .eq('id', payment.order_id)
      .single();

    if (order) {
      await supabase.from('notifications').insert({
        user_id: order.buyer_id,
        type: paymentStatus === 'completed' ? 'payment_received' : 'payment_failed',
        title: paymentStatus === 'completed' ? 'Payment Successful' : 'Payment Failed',
        message: paymentStatus === 'completed'
          ? `Payment for order #${order.order_number} was successful`
          : `Payment for order #${order.order_number} failed. Please try again.`,
        data: { orderId: payment.order_id },
        created_at: new Date().toISOString(),
      });
    }
  }

  res.status(200).json({ success: true });
});

/**
 * @desc    Airtel Money callback
 * @route   POST /api/v1/payments/airtel/callback
 */
const airtelCallback = asyncHandler(async (req, res) => {
  const { transaction } = req.body;

  logger.info('Airtel callback received:', req.body);

  if (transaction) {
    const paymentStatus = transaction.status === 'TI' ? 'completed' : 'failed';

    const { data: payment } = await supabase
      .from('payments')
      .update({
        status: paymentStatus,
        provider_reference: transaction.airtel_money_id,
        updated_at: new Date().toISOString(),
      })
      .eq('transaction_ref', transaction.id)
      .select()
      .single();

    if (payment) {
      await supabase
        .from('orders')
        .update({
          payment_status: paymentStatus,
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.order_id);
    }
  }

  res.status(200).json({ success: true });
});

/**
 * @desc    Relworx callback/webhook (if supported by Relworx)
 * @route   POST /api/v1/payments/relworx/callback
 * @note    Relworx may send callbacks for payment status updates
 */
const relworxCallback = asyncHandler(async (req, res) => {
  logger.info('Relworx callback received:', req.body);

  // Relworx callback payload structure (adapt based on actual callback format)
  const { customer_reference, internal_reference, status, amount, provider } = req.body;

  if (!customer_reference && !internal_reference) {
    return res.status(400).json({ success: false, message: 'Missing reference' });
  }

  // Map Relworx status to our status
  let paymentStatus = 'pending';
  if (status === 'success' || status === 'successful') {
    paymentStatus = 'completed';
  } else if (status === 'failed' || status === 'error') {
    paymentStatus = 'failed';
  }

  // Update payment record
  const { data: payment } = await supabase
    .from('payments')
    .update({
      status: paymentStatus,
      provider_reference: internal_reference,
      updated_at: new Date().toISOString(),
    })
    .eq('transaction_ref', customer_reference || internal_reference)
    .select()
    .single();

  if (payment) {
    // Update order payment status
    await supabase
      .from('orders')
      .update({
        payment_status: paymentStatus,
        updated_at: new Date().toISOString(),
      })
      .eq('id', payment.order_id);

    // Notify user
    const { data: order } = await supabase
      .from('orders')
      .select('buyer_id, order_number')
      .eq('id', payment.order_id)
      .single();

    if (order) {
      await supabase.from('notifications').insert({
        user_id: order.buyer_id,
        type: paymentStatus === 'completed' ? 'payment_received' : 'payment_failed',
        title: paymentStatus === 'completed' ? 'Payment Successful' : 'Payment Failed',
        message: paymentStatus === 'completed'
          ? `Payment for order #${order.order_number} was successful via ${provider}`
          : `Payment for order #${order.order_number} failed. Please try again.`,
        data: { orderId: payment.order_id },
        created_at: new Date().toISOString(),
      });
    }
  }

  res.status(200).json({ success: true });
});

/**
 * @desc    Validate mobile money number
 * @route   POST /api/v1/payments/validate-phone
 * @access  Private
 */
const validatePhone = asyncHandler(async (req, res) => {
  const { phone } = req.body;

  if (!phone) {
    throw new ApiError(400, 'Phone number is required');
  }

  const formattedPhone = relworxService.formatPhoneNumber(phone);
  if (!formattedPhone) {
    throw new ApiError(400, 'Invalid phone number format');
  }

  const provider = relworxService.getProvider(phone);
  
  // Call Relworx validation
  const validation = await relworxService.validateMobileNumber(formattedPhone);

  res.json({
    success: true,
    data: {
      phone: formattedPhone,
      provider: provider,
      valid: validation.valid,
      customerName: validation.customerName,
      message: validation.message,
    },
  });
});

/**
 * @desc    Check Relworx wallet balance
 * @route   GET /api/v1/payments/wallet-balance
 * @access  Private (Admin)
 */
const checkWalletBalance = asyncHandler(async (req, res) => {
  const { currency = 'UGX' } = req.query;

  const balance = await relworxService.checkWalletBalance(currency);

  res.json({
    success: true,
    data: balance,
  });
});

/**
 * @desc    Get Relworx transaction history
 * @route   GET /api/v1/payments/relworx-transactions
 * @access  Private (Admin)
 */
const getRelworxTransactions = asyncHandler(async (req, res) => {
  const history = await relworxService.getTransactionHistory();

  res.json({
    success: true,
    data: history,
  });
});

/**
 * @desc    Card payment callback (Flutterwave)
 * @route   POST /api/v1/payments/card/callback
 */
const cardCallback = asyncHandler(async (req, res) => {
  const { event, data } = req.body;

  logger.info('Flutterwave callback received:', req.body);

  if (event === 'charge.completed' && data) {
    const paymentStatus = data.status === 'successful' ? 'completed' : 'failed';

    const { data: payment } = await supabase
      .from('payments')
      .update({
        status: paymentStatus,
        provider_reference: data.flw_ref,
        updated_at: new Date().toISOString(),
      })
      .eq('transaction_ref', data.tx_ref)
      .select()
      .single();

    if (payment) {
      await supabase
        .from('orders')
        .update({
          payment_status: paymentStatus,
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.order_id);
    }
  }

  res.status(200).json({ success: true });
});

/**
 * @desc    Verify payment transaction
 * @route   GET /api/v1/payments/verify/:transactionId
 */
const verifyPayment = asyncHandler(async (req, res) => {
  const { transactionId } = req.params;

  const { data: payment } = await supabase
    .from('payments')
    .select('*')
    .eq('transaction_ref', transactionId)
    .single();

  if (!payment) {
    throw new ApiError(404, 'Payment not found');
  }

  // For Relworx, check status via API
  if (payment.method === 'relworx_mobile' && payment.status === 'pending') {
    try {
      const statusData = await relworxService.checkRequestStatus(payment.provider_reference || transactionId);

      let paymentStatus = 'pending';
      if (statusData.status === 'success') {
        paymentStatus = 'completed';
      } else if (statusData.status === 'failed') {
        paymentStatus = 'failed';
      }

      if (paymentStatus !== 'pending') {
        await supabase
          .from('payments')
          .update({ 
            status: paymentStatus, 
            provider_reference: statusData.providerTransactionId,
            updated_at: new Date().toISOString() 
          })
          .eq('id', payment.id);

        await supabase
          .from('orders')
          .update({ payment_status: paymentStatus, updated_at: new Date().toISOString() })
          .eq('id', payment.order_id);

        payment.status = paymentStatus;
      }
    } catch (error) {
      logger.error('Verify Relworx payment error:', error);
    }
  }

  // For MTN, check status via API
  if (payment.method === 'mtn_mobile' && payment.status === 'pending') {
    try {
      const tokenResponse = await axios.post(
        `${MTN_API_URL}/collection/token/`,
        {},
        {
          headers: {
            'Authorization': `Basic ${Buffer.from(`${process.env.MTN_API_KEY}:${process.env.MTN_API_SECRET}`).toString('base64')}`,
            'Ocp-Apim-Subscription-Key': process.env.MTN_SUBSCRIPTION_KEY,
          },
        }
      );

      const statusResponse = await axios.get(
        `${MTN_API_URL}/collection/v1_0/requesttopay/${transactionId}`,
        {
          headers: {
            'Authorization': `Bearer ${tokenResponse.data.access_token}`,
            'X-Target-Environment': process.env.MTN_ENVIRONMENT || 'sandbox',
            'Ocp-Apim-Subscription-Key': process.env.MTN_SUBSCRIPTION_KEY,
          },
        }
      );

      const mtnStatus = statusResponse.data.status;
      const paymentStatus = mtnStatus === 'SUCCESSFUL' ? 'completed' : mtnStatus === 'FAILED' ? 'failed' : 'pending';

      if (paymentStatus !== 'pending') {
        await supabase
          .from('payments')
          .update({ status: paymentStatus, updated_at: new Date().toISOString() })
          .eq('id', payment.id);

        await supabase
          .from('orders')
          .update({ payment_status: paymentStatus, updated_at: new Date().toISOString() })
          .eq('id', payment.order_id);

        payment.status = paymentStatus;
      }
    } catch (error) {
      logger.error('Verify MTN payment error:', error);
    }
  }

  res.json({
    success: true,
    data: payment,
  });
});

/**
 * @desc    Retry failed payment
 * @route   POST /api/v1/payments/:orderId/retry
 */
const retryPayment = asyncHandler(async (req, res) => {
  const { orderId } = req.params;
  const { method, phone } = req.body;

  // Reuse initiatePayment logic
  req.body.orderId = orderId;
  return initiatePayment(req, res);
});

/**
 * @desc    Get available payment methods
 * @route   GET /api/v1/payments/methods
 */
const getPaymentMethods = asyncHandler(async (req, res) => {
  res.json({
    success: true,
    data: [
      {
        id: 'relworx_mobile',
        name: 'Mobile Money',
        icon: 'mobile_money',
        description: 'Pay with MTN or Airtel Mobile Money',
        phonePrefixes: ['77', '78', '76', '70', '75', '74'],
        supported: ['MTN Uganda', 'Airtel Uganda'],
        recommended: true, // Primary payment method
      },
      {
        id: 'mtn_mobile',
        name: 'MTN Mobile Money',
        icon: 'mtn',
        description: 'Pay with MTN Mobile Money (Legacy)',
        phonePrefixes: ['77', '78', '76'],
        deprecated: true, // Use relworx_mobile instead
      },
      {
        id: 'airtel_money',
        name: 'Airtel Money',
        icon: 'airtel',
        description: 'Pay with Airtel Money (Legacy)',
        phonePrefixes: ['70', '75', '74'],
        deprecated: true, // Use relworx_mobile instead
      },
      {
        id: 'card',
        name: 'Card Payment',
        icon: 'card',
        description: 'Pay with Visa or Mastercard',
      },
      {
        id: 'cash_on_delivery',
        name: 'Cash on Delivery',
        icon: 'cash',
        description: 'Pay when you receive your order',
      },
    ],
  });
});

/**
 * @desc    Process refund for order
 * @route   POST /api/v1/payments/:orderId/refund
 */
const processRefund = asyncHandler(async (req, res) => {
  const { orderId } = req.params;
  const { amount, reason } = req.body;

  // Only admin can process refunds
  if (req.user.role !== 'admin') {
    throw new ApiError(403, 'Only admins can process refunds');
  }

  const { data: payment } = await supabase
    .from('payments')
    .select('*')
    .eq('order_id', orderId)
    .eq('status', 'completed')
    .single();

  if (!payment) {
    throw new ApiError(404, 'Completed payment not found');
  }

  const refundAmount = amount || payment.amount;

  // Create refund record
  const { error } = await supabase.from('refunds').insert({
    payment_id: payment.id,
    order_id: orderId,
    amount: refundAmount,
    reason,
    status: 'pending',
    processed_by: req.user.id,
    created_at: new Date().toISOString(),
  });

  if (error) {
    logger.error('Create refund error:', error);
    throw new ApiError(400, 'Failed to process refund');
  }

  // Update order
  await supabase
    .from('orders')
    .update({
      status: 'refunded',
      payment_status: 'refunded',
      updated_at: new Date().toISOString(),
    })
    .eq('id', orderId);

  // Notify user
  const { data: order } = await supabase
    .from('orders')
    .select('buyer_id, order_number')
    .eq('id', orderId)
    .single();

  if (order) {
    await supabase.from('notifications').insert({
      user_id: order.buyer_id,
      type: 'refund_processed',
      title: 'Refund Processed',
      message: `Refund of UGX ${refundAmount.toLocaleString()} for order #${order.order_number} has been processed`,
      data: { orderId },
      created_at: new Date().toISOString(),
    });
  }

  res.json({
    success: true,
    message: 'Refund processed successfully',
  });
});

/**
 * @desc    Get payment history for current user
 * @route   GET /api/v1/payments/history
 */
const getPaymentHistory = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { page = 1, limit = 20 } = req.query;
  const offset = (page - 1) * limit;

  const { data, count, error } = await supabase
    .from('payments')
    .select(`
      *,
      order:order_id (order_number, status)
    `, { count: 'exact' })
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .range(offset, offset + parseInt(limit) - 1);

  if (error) {
    logger.error('Get payment history error:', error);
    throw new ApiError(400, 'Failed to fetch payment history');
  }

  res.json({
    success: true,
    data,
    pagination: {
      total: count,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages: Math.ceil(count / limit),
    },
  });
});

module.exports = {
  initiatePayment,
  getPaymentStatus,
  mtnCallback,
  airtelCallback,
  cardCallback,
  relworxCallback,
  validatePhone,
  checkWalletBalance,
  getRelworxTransactions,
  verifyPayment,
  retryPayment,
  getPaymentMethods,
  processRefund,
  getPaymentHistory,
};
