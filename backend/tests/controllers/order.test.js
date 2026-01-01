/**
 * Order Controller Tests
 * Tests for order management endpoints
 */

const request = require('supertest');
const express = require('express');
const orderController = require('../../src/controllers/orderController');
const { authenticate } = require('../../src/middleware/authMiddleware');
const { supabase } = require('../../src/config/supabase');

// Mock auth middleware
jest.mock('../../src/middleware/authMiddleware', () => ({
  authenticate: (req, res, next) => {
    req.user = global.testUtils.createTestUser();
    next();
  },
  authorize: (...roles) => (req, res, next) => next(),
}));

// Create test app
const createTestApp = () => {
  const app = express();
  app.use(express.json());
  
  // Order routes
  app.post('/orders', authenticate, orderController.createOrder);
  app.get('/orders', authenticate, orderController.getOrders);
  app.get('/orders/:id', authenticate, orderController.getOrderById);
  app.post('/orders/:id/cancel', authenticate, orderController.cancelOrder);
  app.put('/orders/:id/status', authenticate, orderController.updateOrderStatus);
  
  return app;
};

describe('Order Controller', () => {
  let app;

  beforeAll(() => {
    app = createTestApp();
  });

  describe('POST /orders', () => {
    it('should create a new order', async () => {
      const orderData = {
        items: [
          { productId: 'product-1', quantity: 2 },
          { productId: 'product-2', quantity: 1 },
        ],
        deliveryAddress: 'Plot 123, Kampala Road, Kampala',
        deliveryNotes: 'Call before delivery',
        paymentMethod: 'mtn_mobile_money',
      };

      // Mock product fetch
      supabase.from().select().in.mockResolvedValueOnce({
        data: [
          global.testUtils.createTestProduct({ id: 'product-1', price: 35000, stock: 10 }),
          global.testUtils.createTestProduct({ id: 'product-2', price: 50000, stock: 5 }),
        ],
        error: null,
      });

      // Mock order insert
      supabase.from().insert().select().single.mockResolvedValueOnce({
        data: global.testUtils.createTestOrder({
          items: orderData.items,
          subtotal: 120000,
          total: 125000,
        }),
        error: null,
      });

      // Mock order items insert
      supabase.from().insert.mockResolvedValueOnce({
        data: null,
        error: null,
      });

      // Mock stock update
      supabase.from().update().eq.mockResolvedValue({
        data: null,
        error: null,
      });

      const response = await request(app)
        .post('/orders')
        .send(orderData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('created');
      expect(response.body.data.orderNumber).toBeDefined();
    });

    it('should fail with empty cart', async () => {
      const orderData = {
        items: [],
        deliveryAddress: 'Test Address',
        paymentMethod: 'mtn_mobile_money',
      };

      const response = await request(app)
        .post('/orders')
        .send(orderData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should fail when product is out of stock', async () => {
      const orderData = {
        items: [
          { productId: 'product-1', quantity: 100 }, // More than available
        ],
        deliveryAddress: 'Test Address',
        paymentMethod: 'mtn_mobile_money',
      };

      // Mock product fetch with low stock
      supabase.from().select().in.mockResolvedValueOnce({
        data: [
          global.testUtils.createTestProduct({ id: 'product-1', stock: 5 }),
        ],
        error: null,
      });

      const response = await request(app)
        .post('/orders')
        .send(orderData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('stock');
    });

    it('should fail with missing delivery address', async () => {
      const orderData = {
        items: [
          { productId: 'product-1', quantity: 1 },
        ],
        paymentMethod: 'mtn_mobile_money',
        // Missing deliveryAddress
      };

      const response = await request(app)
        .post('/orders')
        .send(orderData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should fail with invalid payment method', async () => {
      const orderData = {
        items: [
          { productId: 'product-1', quantity: 1 },
        ],
        deliveryAddress: 'Test Address',
        paymentMethod: 'invalid_method',
      };

      const response = await request(app)
        .post('/orders')
        .send(orderData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /orders', () => {
    it('should return user orders', async () => {
      const mockOrders = [
        global.testUtils.createTestOrder({ orderNumber: 'AGR-2024-001' }),
        global.testUtils.createTestOrder({ orderNumber: 'AGR-2024-002' }),
      ];

      supabase.from().select().eq().order().range.mockResolvedValueOnce({
        data: mockOrders,
        error: null,
        count: 2,
      });

      const response = await request(app)
        .get('/orders')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2);
    });

    it('should filter orders by status', async () => {
      const mockOrders = [
        global.testUtils.createTestOrder({ status: 'delivered' }),
      ];

      supabase.from().select().eq().eq().order().range.mockResolvedValueOnce({
        data: mockOrders,
        error: null,
        count: 1,
      });

      const response = await request(app)
        .get('/orders?status=delivered')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data[0].status).toBe('delivered');
    });

    it('should paginate orders', async () => {
      const mockOrders = Array.from({ length: 10 }, (_, i) =>
        global.testUtils.createTestOrder({ orderNumber: `AGR-2024-${i + 1}` })
      );

      supabase.from().select().eq().order().range.mockResolvedValueOnce({
        data: mockOrders,
        error: null,
        count: 25,
      });

      const response = await request(app)
        .get('/orders?page=1&limit=10')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.totalPages).toBe(3);
    });
  });

  describe('GET /orders/:id', () => {
    it('should return order details', async () => {
      const mockOrder = global.testUtils.createTestOrder();
      const mockOrderItems = [
        {
          id: 'item-1',
          productId: 'product-1',
          quantity: 2,
          price: 35000,
          product: global.testUtils.createTestProduct(),
        },
      ];

      // Mock order fetch
      supabase.from().select().eq().eq().single.mockResolvedValueOnce({
        data: mockOrder,
        error: null,
      });

      // Mock order items fetch
      supabase.from().select().eq.mockResolvedValueOnce({
        data: mockOrderItems,
        error: null,
      });

      // Mock status history fetch
      supabase.from().select().eq().order.mockResolvedValueOnce({
        data: [{ status: 'pending', timestamp: new Date().toISOString() }],
        error: null,
      });

      const response = await request(app)
        .get('/orders/test-order-id')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe('test-order-id');
      expect(response.body.data.items).toBeDefined();
    });

    it('should return 404 for non-existent order', async () => {
      supabase.from().select().eq().eq().single.mockResolvedValueOnce({
        data: null,
        error: { code: 'PGRST116' },
      });

      const response = await request(app)
        .get('/orders/non-existent-id')
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('NOT_FOUND');
    });

    it('should not allow access to other user orders', async () => {
      supabase.from().select().eq().eq().single.mockResolvedValueOnce({
        data: global.testUtils.createTestOrder({ userId: 'different-user' }),
        error: null,
      });

      const response = await request(app)
        .get('/orders/test-order-id')
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('FORBIDDEN');
    });
  });

  describe('POST /orders/:id/cancel', () => {
    it('should cancel a pending order', async () => {
      const mockOrder = global.testUtils.createTestOrder({ status: 'pending' });

      // Mock order fetch
      supabase.from().select().eq().eq().single.mockResolvedValueOnce({
        data: mockOrder,
        error: null,
      });

      // Mock order update
      supabase.from().update().eq.mockResolvedValueOnce({
        data: null,
        error: null,
      });

      // Mock status history insert
      supabase.from().insert.mockResolvedValueOnce({
        data: null,
        error: null,
      });

      // Mock stock restore
      supabase.from().select().eq.mockResolvedValueOnce({
        data: [{ productId: 'product-1', quantity: 2 }],
        error: null,
      });

      supabase.rpc = jest.fn().mockResolvedValueOnce({
        data: null,
        error: null,
      });

      const response = await request(app)
        .post('/orders/test-order-id/cancel')
        .send({ reason: 'Changed my mind' })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('cancelled');
    });

    it('should not cancel a delivered order', async () => {
      const mockOrder = global.testUtils.createTestOrder({ status: 'delivered' });

      supabase.from().select().eq().eq().single.mockResolvedValueOnce({
        data: mockOrder,
        error: null,
      });

      const response = await request(app)
        .post('/orders/test-order-id/cancel')
        .send({ reason: 'Want to cancel' })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('cannot be cancelled');
    });

    it('should not cancel a shipped order', async () => {
      const mockOrder = global.testUtils.createTestOrder({ status: 'shipped' });

      supabase.from().select().eq().eq().single.mockResolvedValueOnce({
        data: mockOrder,
        error: null,
      });

      const response = await request(app)
        .post('/orders/test-order-id/cancel')
        .send({ reason: 'Want to cancel' })
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('PUT /orders/:id/status', () => {
    beforeEach(() => {
      // Set up farmer user for status updates
      jest.spyOn(require('../../src/middleware/authMiddleware'), 'authenticate')
        .mockImplementation((req, res, next) => {
          req.user = global.testUtils.createTestFarmer();
          next();
        });
    });

    it('should update order status', async () => {
      const mockOrder = global.testUtils.createTestOrder({ status: 'confirmed' });

      // Mock order fetch with farmer ownership check
      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: { ...mockOrder, farmerId: 'test-farmer-id' },
        error: null,
      });

      // Mock order update
      supabase.from().update().eq.mockResolvedValueOnce({
        data: null,
        error: null,
      });

      // Mock status history insert
      supabase.from().insert.mockResolvedValueOnce({
        data: null,
        error: null,
      });

      const response = await request(app)
        .put('/orders/test-order-id/status')
        .send({ status: 'processing', note: 'Preparing order' })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('updated');
    });

    it('should fail with invalid status transition', async () => {
      const mockOrder = global.testUtils.createTestOrder({ status: 'pending' });

      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: { ...mockOrder, farmerId: 'test-farmer-id' },
        error: null,
      });

      const response = await request(app)
        .put('/orders/test-order-id/status')
        .send({ status: 'delivered' }) // Can't jump from pending to delivered
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('Invalid status transition');
    });

    it('should fail when not order farmer', async () => {
      const mockOrder = global.testUtils.createTestOrder({ status: 'confirmed' });

      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: { ...mockOrder, farmerId: 'different-farmer-id' },
        error: null,
      });

      const response = await request(app)
        .put('/orders/test-order-id/status')
        .send({ status: 'processing' })
        .expect(403);

      expect(response.body.success).toBe(false);
    });
  });
});

describe('Order Status Transitions', () => {
  const validTransitions = {
    pending: ['confirmed', 'cancelled'],
    confirmed: ['processing', 'cancelled'],
    processing: ['shipped', 'cancelled'],
    shipped: ['delivered'],
    delivered: [],
    cancelled: [],
  };

  Object.entries(validTransitions).forEach(([from, toStates]) => {
    if (toStates.length > 0) {
      toStates.forEach((to) => {
        it(`should allow transition from ${from} to ${to}`, () => {
          const isValid = validTransitions[from].includes(to);
          expect(isValid).toBe(true);
        });
      });
    }

    const invalidStates = Object.keys(validTransitions).filter(
      (s) => !toStates.includes(s) && s !== from
    );
    
    invalidStates.forEach((to) => {
      it(`should not allow transition from ${from} to ${to}`, () => {
        const isValid = validTransitions[from].includes(to);
        expect(isValid).toBe(false);
      });
    });
  });
});
