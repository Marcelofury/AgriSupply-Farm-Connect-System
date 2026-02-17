const request = require('supertest');
const express = require('express');
const adminController = require('../../src/controllers/adminController');
const { supabase } = require('../../src/config/supabase');

// Create test app
const createTestApp = () => {
  const app = express();
  app.use(express.json());
  
  // Admin routes
  app.get('/dashboard', adminController.getDashboard);
  app.get('/users', adminController.getUsers);
  app.get('/users/:id', adminController.getUserById);
  app.put('/users/:id', adminController.updateUser);
  app.post('/users/:id/verify', adminController.verifyUser);
  app.post('/users/:id/suspend', adminController.suspendUser);
  app.delete('/users/:id', adminController.deleteUser);
  
  return app;
};

describe('Admin Controller', () => {
  let app;

  beforeAll(() => {
    app = createTestApp();
  });

  describe('GET /dashboard', () => {
    it('should return dashboard statistics', async () => {
      // Mock Supabase responses
      supabase.from().select().order.mockResolvedValueOnce({
        data: [
          { id: '1', role: 'farmer', is_verified: true, is_premium: false },
          { id: '2', role: 'buyer', is_verified: true, is_premium: true },
        ],
        error: null,
      });

      const response = await request(app)
        .get('/dashboard')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('users');
      expect(response.body.data).toHaveProperty('products');
      expect(response.body.data).toHaveProperty('orders');
    });
  });

  describe('GET /users', () => {
    it('should return paginated list of users', async () => {
      const mockUsers = [
        { id: '1', email: 'user1@test.com', role: 'buyer' },
        { id: '2', email: 'user2@test.com', role: 'farmer' },
      ];

      supabase.from().select().range().order.mockResolvedValueOnce({
        data: mockUsers,
        error: null,
        count: 2,
      });

      const response = await request(app)
        .get('/users')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockUsers);
      expect(response.body.pagination).toBeDefined();
    });

    it('should filter users by role', async () => {
      const mockFarmers = [
        { id: '1', email: 'farmer@test.com', role: 'farmer' },
      ];

      supabase.from().select().eq().range().order.mockResolvedValueOnce({
        data: mockFarmers,
        error: null,
        count: 1,
      });

      const response = await request(app)
        .get('/users?role=farmer')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data[0].role).toBe('farmer');
    });
  });

  describe('PUT /users/:id', () => {
    it('should update user successfully', async () => {
      const userId = 'test-user-id';
      const updateData = { is_verified: true };

      supabase.from().update().eq().select().single.mockResolvedValueOnce({
        data: { id: userId, ...updateData },
        error: null,
      });

      const response = await request(app)
        .put(`/users/${userId}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.is_verified).toBe(true);
    });
  });

  describe('POST /users/:id/verify', () => {
    it('should verify user account', async () => {
      const userId = 'test-user-id';

      supabase.from().update().eq().select().single.mockResolvedValueOnce({
        data: { id: userId, is_verified: true },
        error: null,
      });

      const response = await request(app)
        .post(`/users/${userId}/verify`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('verified');
    });
  });

  describe('POST /users/:id/suspend', () => {
    it('should suspend user account', async () => {
      const userId = 'test-user-id';

      supabase.from().update().eq().select().single.mockResolvedValueOnce({
        data: { id: userId, is_suspended: true },
        error: null,
      });

      const response = await request(app)
        .post(`/users/${userId}/suspend`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('suspended');
    });
  });

  describe('DELETE /users/:id', () => {
    it('should delete user account', async () => {
      const userId = 'test-user-id';

      supabase.from().delete().eq.mockResolvedValueOnce({
        error: null,
      });

      const response = await request(app)
        .delete(`/users/${userId}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('deleted');
    });

    it('should fail to delete non-existent user', async () => {
      const userId = 'non-existent-id';

      supabase.from().delete().eq.mockResolvedValueOnce({
        error: { message: 'User not found' },
      });

      await request(app)
        .delete(`/users/${userId}`)
        .expect(400);
    });
  });
});
