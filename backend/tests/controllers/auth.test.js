/**
 * Auth Controller Tests
 * Tests for authentication endpoints
 */

const request = require('supertest');
const express = require('express');
const authController = require('../../src/controllers/authController');
const { supabase } = require('../../src/config/supabase');

// Create test app
const createTestApp = () => {
  const app = express();
  app.use(express.json());
  
  // Auth routes
  app.post('/register', authController.register);
  app.post('/login', authController.login);
  app.post('/refresh-token', authController.refreshToken);
  app.post('/forgot-password', authController.forgotPassword);
  app.post('/reset-password', authController.resetPassword);
  app.post('/verify-otp', authController.verifyOTP);
  
  return app;
};

describe('Auth Controller', () => {
  let app;

  beforeAll(() => {
    app = createTestApp();
  });

  describe('POST /register', () => {
    it('should register a new user successfully', async () => {
      const userData = {
        email: 'newuser@example.com',
        password: 'Password123!',
        fullName: 'New User',
        phone: '+256701234567',
        role: 'buyer',
        region: 'Central',
        district: 'Kampala',
      };

      // Mock Supabase auth
      supabase.auth.signUp.mockResolvedValueOnce({
        data: {
          user: { id: 'new-user-id' },
          session: {
            access_token: 'test-access-token',
            refresh_token: 'test-refresh-token',
          },
        },
        error: null,
      });

      // Mock user insert
      supabase.from().insert().select().single.mockResolvedValueOnce({
        data: {
          id: 'new-user-id',
          email: userData.email,
          full_name: userData.fullName,
          phone: userData.phone,
          role: userData.role,
        },
        error: null,
      });

      const response = await request(app)
        .post('/register')
        .send(userData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('Registration successful');
      expect(response.body.data.accessToken).toBeDefined();
    });

    it('should fail with invalid email', async () => {
      const userData = {
        email: 'invalid-email',
        password: 'Password123!',
        fullName: 'Test User',
        phone: '+256701234567',
        role: 'buyer',
      };

      const response = await request(app)
        .post('/register')
        .send(userData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should fail with weak password', async () => {
      const userData = {
        email: 'test@example.com',
        password: '123',
        fullName: 'Test User',
        phone: '+256701234567',
        role: 'buyer',
      };

      const response = await request(app)
        .post('/register')
        .send(userData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should fail with invalid phone number', async () => {
      const userData = {
        email: 'test@example.com',
        password: 'Password123!',
        fullName: 'Test User',
        phone: '1234567890', // Invalid - not Ugandan format
        role: 'buyer',
      };

      const response = await request(app)
        .post('/register')
        .send(userData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should fail when email already exists', async () => {
      const userData = {
        email: 'existing@example.com',
        password: 'Password123!',
        fullName: 'Test User',
        phone: '+256701234567',
        role: 'buyer',
      };

      // Mock Supabase returning duplicate error
      supabase.auth.signUp.mockResolvedValueOnce({
        data: null,
        error: { message: 'User already registered' },
      });

      const response = await request(app)
        .post('/register')
        .send(userData)
        .expect(409);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('CONFLICT');
    });
  });

  describe('POST /login', () => {
    it('should login successfully with valid credentials', async () => {
      const credentials = {
        email: 'test@example.com',
        password: 'Password123!',
      };

      // Mock Supabase auth
      supabase.auth.signInWithPassword.mockResolvedValueOnce({
        data: {
          user: { id: 'test-user-id' },
          session: {
            access_token: 'test-access-token',
            refresh_token: 'test-refresh-token',
          },
        },
        error: null,
      });

      // Mock user fetch
      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: global.testUtils.createTestUser(),
        error: null,
      });

      const response = await request(app)
        .post('/login')
        .send(credentials)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Login successful');
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.user).toBeDefined();
    });

    it('should fail with invalid credentials', async () => {
      const credentials = {
        email: 'test@example.com',
        password: 'WrongPassword',
      };

      // Mock Supabase returning error
      supabase.auth.signInWithPassword.mockResolvedValueOnce({
        data: null,
        error: { message: 'Invalid login credentials' },
      });

      const response = await request(app)
        .post('/login')
        .send(credentials)
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('UNAUTHORIZED');
    });

    it('should fail with missing email', async () => {
      const credentials = {
        password: 'Password123!',
      };

      const response = await request(app)
        .post('/login')
        .send(credentials)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should fail with missing password', async () => {
      const credentials = {
        email: 'test@example.com',
      };

      const response = await request(app)
        .post('/login')
        .send(credentials)
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('POST /refresh-token', () => {
    it('should refresh token successfully', async () => {
      // Mock token refresh
      supabase.auth.refreshSession = jest.fn().mockResolvedValueOnce({
        data: {
          session: {
            access_token: 'new-access-token',
            refresh_token: 'new-refresh-token',
          },
        },
        error: null,
      });

      const response = await request(app)
        .post('/refresh-token')
        .send({ refreshToken: 'valid-refresh-token' })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.accessToken).toBeDefined();
    });

    it('should fail with invalid refresh token', async () => {
      // Mock token refresh failure
      supabase.auth.refreshSession = jest.fn().mockResolvedValueOnce({
        data: null,
        error: { message: 'Invalid refresh token' },
      });

      const response = await request(app)
        .post('/refresh-token')
        .send({ refreshToken: 'invalid-token' })
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });

  describe('POST /forgot-password', () => {
    it('should send reset email successfully', async () => {
      // Mock password reset
      supabase.auth.resetPasswordForEmail = jest.fn().mockResolvedValueOnce({
        data: {},
        error: null,
      });

      const response = await request(app)
        .post('/forgot-password')
        .send({ email: 'test@example.com' })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('reset link sent');
    });

    it('should not reveal if email exists', async () => {
      // Mock password reset for non-existent email
      supabase.auth.resetPasswordForEmail = jest.fn().mockResolvedValueOnce({
        data: {},
        error: null,
      });

      const response = await request(app)
        .post('/forgot-password')
        .send({ email: 'nonexistent@example.com' })
        .expect(200);

      // Should return success even for non-existent email (security)
      expect(response.body.success).toBe(true);
    });
  });

  describe('POST /reset-password', () => {
    it('should reset password successfully', async () => {
      // Mock password update
      supabase.auth.updateUser = jest.fn().mockResolvedValueOnce({
        data: { user: { id: 'test-user-id' } },
        error: null,
      });

      const response = await request(app)
        .post('/reset-password')
        .send({
          token: 'valid-reset-token',
          password: 'NewPassword123!',
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('Password reset successful');
    });

    it('should fail with invalid token', async () => {
      // Mock password update failure
      supabase.auth.updateUser = jest.fn().mockResolvedValueOnce({
        data: null,
        error: { message: 'Invalid token' },
      });

      const response = await request(app)
        .post('/reset-password')
        .send({
          token: 'invalid-token',
          password: 'NewPassword123!',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('POST /verify-otp', () => {
    it('should verify OTP successfully', async () => {
      // Mock OTP verification
      supabase.auth.verifyOtp = jest.fn().mockResolvedValueOnce({
        data: { user: { id: 'test-user-id' } },
        error: null,
      });

      const response = await request(app)
        .post('/verify-otp')
        .send({
          phone: '+256701234567',
          otp: '123456',
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('verified');
    });

    it('should fail with invalid OTP', async () => {
      // Mock OTP verification failure
      supabase.auth.verifyOtp = jest.fn().mockResolvedValueOnce({
        data: null,
        error: { message: 'Invalid OTP' },
      });

      const response = await request(app)
        .post('/verify-otp')
        .send({
          phone: '+256701234567',
          otp: '000000',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });
});
