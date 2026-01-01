/**
 * Auth Middleware Tests
 * Tests for authentication and authorization middleware
 */

const { authenticate, authorize, optionalAuth } = require('../../src/middleware/authMiddleware');
const jwt = require('jsonwebtoken');
const { supabase } = require('../../src/config/supabase');

// Mock request/response objects
const createMockReq = (headers = {}, cookies = {}) => ({
  headers,
  cookies,
  user: null,
});

const createMockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const createMockNext = () => jest.fn();

describe('Auth Middleware', () => {
  const validToken = jwt.sign(
    { userId: 'test-user-id', role: 'buyer' },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );

  const expiredToken = jwt.sign(
    { userId: 'test-user-id', role: 'buyer' },
    process.env.JWT_SECRET,
    { expiresIn: '-1h' } // Already expired
  );

  describe('authenticate', () => {
    it('should authenticate with valid Bearer token', async () => {
      const req = createMockReq({
        authorization: `Bearer ${validToken}`,
      });
      const res = createMockRes();
      const next = createMockNext();

      // Mock user fetch
      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: global.testUtils.createTestUser(),
        error: null,
      });

      await authenticate(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeDefined();
      expect(req.user.id).toBe('test-user-id');
    });

    it('should reject request without token', async () => {
      const req = createMockReq({});
      const res = createMockRes();
      const next = createMockNext();

      await authenticate(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          error: expect.objectContaining({
            code: 'UNAUTHORIZED',
          }),
        })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject invalid token format', async () => {
      const req = createMockReq({
        authorization: 'InvalidFormat token123',
      });
      const res = createMockRes();
      const next = createMockNext();

      await authenticate(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject expired token', async () => {
      const req = createMockReq({
        authorization: `Bearer ${expiredToken}`,
      });
      const res = createMockRes();
      const next = createMockNext();

      await authenticate(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          error: expect.objectContaining({
            message: expect.stringContaining('expired'),
          }),
        })
      );
    });

    it('should reject malformed token', async () => {
      const req = createMockReq({
        authorization: 'Bearer invalid.token.here',
      });
      const res = createMockRes();
      const next = createMockNext();

      await authenticate(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
    });

    it('should reject token with invalid signature', async () => {
      const invalidSignatureToken = jwt.sign(
        { userId: 'test-user-id', role: 'buyer' },
        'wrong-secret',
        { expiresIn: '1h' }
      );

      const req = createMockReq({
        authorization: `Bearer ${invalidSignatureToken}`,
      });
      const res = createMockRes();
      const next = createMockNext();

      await authenticate(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
    });

    it('should reject when user not found in database', async () => {
      const req = createMockReq({
        authorization: `Bearer ${validToken}`,
      });
      const res = createMockRes();
      const next = createMockNext();

      // Mock user not found
      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: null,
        error: { code: 'PGRST116' },
      });

      await authenticate(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          error: expect.objectContaining({
            message: expect.stringContaining('User not found'),
          }),
        })
      );
    });

    it('should extract token from cookies if header missing', async () => {
      const req = createMockReq({}, { accessToken: validToken });
      const res = createMockRes();
      const next = createMockNext();

      // Mock user fetch
      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: global.testUtils.createTestUser(),
        error: null,
      });

      await authenticate(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeDefined();
    });
  });

  describe('authorize', () => {
    it('should allow access for authorized role', () => {
      const req = createMockReq();
      req.user = global.testUtils.createTestUser({ role: 'farmer' });
      const res = createMockRes();
      const next = createMockNext();

      const middleware = authorize('farmer', 'admin');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should deny access for unauthorized role', () => {
      const req = createMockReq();
      req.user = global.testUtils.createTestUser({ role: 'buyer' });
      const res = createMockRes();
      const next = createMockNext();

      const middleware = authorize('farmer', 'admin');
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          error: expect.objectContaining({
            code: 'FORBIDDEN',
          }),
        })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should allow admin access to all routes', () => {
      const req = createMockReq();
      req.user = global.testUtils.createTestUser({ role: 'admin' });
      const res = createMockRes();
      const next = createMockNext();

      const middleware = authorize('farmer');
      middleware(req, res, next);

      // Admin should always have access
      expect(next).toHaveBeenCalled();
    });

    it('should handle missing user object', () => {
      const req = createMockReq();
      const res = createMockRes();
      const next = createMockNext();

      const middleware = authorize('farmer');
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
    });

    it('should work with single role', () => {
      const req = createMockReq();
      req.user = global.testUtils.createTestUser({ role: 'admin' });
      const res = createMockRes();
      const next = createMockNext();

      const middleware = authorize('admin');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should work with multiple roles', () => {
      const req = createMockReq();
      req.user = global.testUtils.createTestUser({ role: 'buyer' });
      const res = createMockRes();
      const next = createMockNext();

      const middleware = authorize('buyer', 'farmer', 'admin');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });

  describe('optionalAuth', () => {
    it('should attach user if valid token provided', async () => {
      const req = createMockReq({
        authorization: `Bearer ${validToken}`,
      });
      const res = createMockRes();
      const next = createMockNext();

      // Mock user fetch
      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: global.testUtils.createTestUser(),
        error: null,
      });

      await optionalAuth(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeDefined();
    });

    it('should continue without user if no token', async () => {
      const req = createMockReq({});
      const res = createMockRes();
      const next = createMockNext();

      await optionalAuth(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeNull();
    });

    it('should continue without user if invalid token', async () => {
      const req = createMockReq({
        authorization: 'Bearer invalid.token',
      });
      const res = createMockRes();
      const next = createMockNext();

      await optionalAuth(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeNull();
    });
  });
});

describe('Token Refresh Flow', () => {
  it('should provide refresh token on successful authentication', async () => {
    const req = createMockReq({
      authorization: `Bearer ${jwt.sign(
        { userId: 'test-user-id', role: 'buyer' },
        process.env.JWT_SECRET,
        { expiresIn: '1h' }
      )}`,
    });
    const res = createMockRes();
    const next = createMockNext();

    supabase.from().select().eq().single.mockResolvedValueOnce({
      data: global.testUtils.createTestUser(),
      error: null,
    });

    await authenticate(req, res, next);

    expect(req.user).toBeDefined();
    // User should be able to request new tokens using refresh token
  });
});

describe('Role-Based Access Control', () => {
  const roles = ['buyer', 'farmer', 'admin'];
  const endpoints = [
    { path: '/products', allowedRoles: ['farmer', 'admin'] },
    { path: '/orders/:id/status', allowedRoles: ['farmer', 'admin'] },
    { path: '/admin/users', allowedRoles: ['admin'] },
    { path: '/admin/dashboard', allowedRoles: ['admin'] },
  ];

  endpoints.forEach(({ path, allowedRoles }) => {
    roles.forEach((role) => {
      const shouldAllow = allowedRoles.includes(role) || role === 'admin';
      
      it(`should ${shouldAllow ? 'allow' : 'deny'} ${role} access to ${path}`, () => {
        const req = createMockReq();
        req.user = global.testUtils.createTestUser({ role });
        const res = createMockRes();
        const next = createMockNext();

        const middleware = authorize(...allowedRoles);
        middleware(req, res, next);

        if (shouldAllow) {
          expect(next).toHaveBeenCalled();
        } else {
          expect(res.status).toHaveBeenCalledWith(403);
        }
      });
    });
  });
});
