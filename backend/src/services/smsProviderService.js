const axios = require('axios');
const logger = require('../utils/logger');

/**
 * Send SMS using configured provider.
 * Supports egosms (preferred), twilio, africas_talking.
 */
async function sendSms({ phone, message }) {
  const provider = (process.env.SMS_SERVICE || '').toLowerCase();

  if (!provider) {
    logger.warn('SMS_SERVICE is not configured');
    return { ok: false, reason: 'no_provider' };
  }

  if (provider === 'egosms') {
    return sendViaEgoSms({ phone, message });
  }

  if (provider === 'twilio') {
    return sendViaTwilio({ phone, message });
  }

  if (provider === 'africas_talking') {
    return sendViaAfricasTalking({ phone, message });
  }

  logger.warn(`Unsupported SMS_SERVICE provider: ${provider}`);
  return { ok: false, reason: 'unsupported_provider' };
}

async function sendViaEgoSms({ phone, message }) {
  const apiUrl = process.env.EGOSMS_API_URL;
  const username = process.env.EGOSMS_USERNAME;
  const password = process.env.EGOSMS_PASSWORD;
  const senderId = process.env.EGOSMS_SENDER_ID;

  if (!apiUrl || !username || !password || !senderId) {
    logger.warn('EgoSMS env vars missing: EGOSMS_API_URL/USERNAME/PASSWORD/SENDER_ID');
    return { ok: false, reason: 'missing_egosms_config' };
  }

  try {
    const payload = {
      username,
      password,
      sender: senderId,
      msisdn: phone,
      message,
    };

    const { data } = await axios.post(apiUrl, payload, {
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 10000,
    });

    logger.info('EgoSMS send response received', { provider: 'egosms' });

    const responseText = typeof data === 'string' ? data.toLowerCase() : '';
    if (responseText.includes('error')) {
      return { ok: false, reason: 'egosms_error', providerResponse: data };
    }

    return { ok: true, providerResponse: data };
  } catch (error) {
    logger.error('EgoSMS send failed:', error.response?.data || error.message || error);
    return { ok: false, reason: 'egosms_request_failed' };
  }
}

async function sendViaTwilio({ phone, message }) {
  try {
    const twilio = require('twilio');
    const client = twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );

    await client.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phone,
    });

    return { ok: true };
  } catch (error) {
    logger.error('Twilio send failed:', error.message || error);
    return { ok: false, reason: 'twilio_request_failed' };
  }
}

async function sendViaAfricasTalking({ phone, message }) {
  try {
    const AfricasTalking = require('africastalking')({
      apiKey: process.env.AFRICAS_TALKING_API_KEY,
      username: process.env.AFRICAS_TALKING_USERNAME,
    });

    await AfricasTalking.SMS.send({
      to: [phone],
      message,
      from: process.env.AFRICAS_TALKING_SENDER_ID,
    });

    return { ok: true };
  } catch (error) {
    logger.error("Africa's Talking send failed:", error.message || error);
    return { ok: false, reason: 'africas_talking_request_failed' };
  }
}

module.exports = {
  sendSms,
};
