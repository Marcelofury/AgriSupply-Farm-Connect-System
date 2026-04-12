const request = require('supertest');
const express = require('express');

jest.mock('../../src/services/smsProviderService', () => ({
  sendSms: jest.fn(),
}));

jest.mock('../../src/services/passwordResetOtpService', () => ({
  issueOtp: jest.fn(),
  verifyOtp: jest.fn(),
  consumeResetToken: jest.fn(),
}));

const authController = require('../../src/controllers/authController');
const { supabase } = require('../../src/config/supabase');
const { sendSms } = require('../../src/services/smsProviderService');
const {
  issueOtp,
  verifyOtp,
  consumeResetToken,
} = require('../../src/services/passwordResetOtpService');

function createTestApp() {
  const app = express();
  app.use(express.json());

  app.post('/password-reset/send-otp', authController.sendPasswordResetOtp);
  app.post('/password-reset/verify-otp', authController.verifyPasswordResetOtp);
  app.post('/password-reset/confirm', authController.confirmPasswordResetWithOtp);

  return app;
}

describe('Auth password reset OTP endpoints', () => {
  let app;

  beforeAll(() => {
    app = createTestApp();
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('POST /password-reset/send-otp returns success and sends sms for existing phone', async () => {
    const chain = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      maybeSingle: jest.fn().mockResolvedValue({
        data: { id: 'u-1', phone: '+256772123456' },
        error: null,
      }),
    };

    supabase.from = jest.fn().mockReturnValue(chain);
    issueOtp.mockReturnValue({ ok: true, otp: '123456' });
    sendSms.mockResolvedValue({ ok: true });

    const response = await request(app)
      .post('/password-reset/send-otp')
      .send({ phone: '0772123456' })
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(issueOtp).toHaveBeenCalled();
    expect(sendSms).toHaveBeenCalledWith(
      expect.objectContaining({ phone: '+256772123456' })
    );
  });

  it('POST /password-reset/verify-otp returns reset token', async () => {
    verifyOtp.mockReturnValue({ ok: true, resetToken: 'reset-token-123' });

    const response = await request(app)
      .post('/password-reset/verify-otp')
      .send({ phone: '0772123456', otp: '123456' })
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data.resetToken).toBe('reset-token-123');
  });

  it('POST /password-reset/confirm updates user password', async () => {
    consumeResetToken.mockReturnValue({ ok: true, userId: 'u-1' });
    supabase.auth.admin.updateUserById.mockResolvedValue({ error: null });

    const response = await request(app)
      .post('/password-reset/confirm')
      .send({
        phone: '0772123456',
        resetToken: 'reset-token-123',
        newPassword: 'newpass123',
      })
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(supabase.auth.admin.updateUserById).toHaveBeenCalledWith('u-1', {
      password: 'newpass123',
    });
  });
});
