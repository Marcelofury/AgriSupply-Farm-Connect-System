const {
  issueOtp,
  verifyOtp,
  consumeResetToken,
} = require('../../src/services/passwordResetOtpService');

describe('passwordResetOtpService', () => {
  const phone = '+256772123456';
  const userId = 'test-user-id';

  it('issues OTP and verifies with token consumption', () => {
    const issued = issueOtp(phone, userId);
    expect(issued.ok).toBe(true);
    expect(issued.otp).toHaveLength(6);

    const verified = verifyOtp(phone, issued.otp);
    expect(verified.ok).toBe(true);
    expect(typeof verified.resetToken).toBe('string');
    expect(verified.resetToken.length).toBeGreaterThan(10);

    const consumed = consumeResetToken(phone, verified.resetToken);
    expect(consumed.ok).toBe(true);
    expect(consumed.userId).toBe(userId);
  });

  it('rejects invalid OTP', () => {
    const issued = issueOtp('+256701000001', 'u-1');
    expect(issued.ok).toBe(true);

    const verified = verifyOtp('+256701000001', '000000');
    expect(verified.ok).toBe(false);
    expect(verified.reason).toBe('invalid_otp');
  });
});
