/**
 * Product Controller Tests
 * Tests for product management endpoints
 */

const request = require('supertest');
const express = require('express');
const productController = require('../../src/controllers/productController');
const { authenticate, authorize } = require('../../src/middleware/authMiddleware');
const { supabase } = require('../../src/config/supabase');

// Mock auth middleware
jest.mock('../../src/middleware/authMiddleware', () => ({
  authenticate: (req, res, next) => {
    req.user = global.testUtils.createTestUser();
    next();
  },
  authorize: (...roles) => (req, res, next) => {
    if (roles.includes(req.user.role)) {
      next();
    } else {
      res.status(403).json({ success: false, error: { code: 'FORBIDDEN' } });
    }
  },
}));

// Create test app
const createTestApp = () => {
  const app = express();
  app.use(express.json());
  
  // Product routes
  app.get('/products', productController.getProducts);
  app.get('/products/:id', productController.getProductById);
  app.post('/products', authenticate, authorize('farmer', 'admin'), productController.createProduct);
  app.put('/products/:id', authenticate, authorize('farmer', 'admin'), productController.updateProduct);
  app.delete('/products/:id', authenticate, authorize('farmer', 'admin'), productController.deleteProduct);
  app.post('/products/:id/favorite', authenticate, productController.addToFavorites);
  app.delete('/products/:id/favorite', authenticate, productController.removeFromFavorites);
  app.get('/products/:id/reviews', productController.getProductReviews);
  app.post('/products/:id/reviews', authenticate, productController.addReview);
  
  return app;
};

describe('Product Controller', () => {
  let app;

  beforeAll(() => {
    app = createTestApp();
  });

  describe('GET /products', () => {
    it('should return list of products', async () => {
      const mockProducts = [
        global.testUtils.createTestProduct({ id: '1', name: 'Product 1' }),
        global.testUtils.createTestProduct({ id: '2', name: 'Product 2' }),
      ];

      // Mock Supabase query
      supabase.from().select().order().range.mockResolvedValueOnce({
        data: mockProducts,
        error: null,
        count: 2,
      });

      const response = await request(app)
        .get('/products')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2);
      expect(response.body.pagination).toBeDefined();
    });

    it('should filter products by category', async () => {
      const mockProducts = [
        global.testUtils.createTestProduct({ category: 'fruits_vegetables' }),
      ];

      supabase.from().select().eq().order().range.mockResolvedValueOnce({
        data: mockProducts,
        error: null,
        count: 1,
      });

      const response = await request(app)
        .get('/products?category=fruits_vegetables')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data[0].category).toBe('fruits_vegetables');
    });

    it('should filter products by region', async () => {
      const mockProducts = [
        global.testUtils.createTestProduct({ region: 'Central' }),
      ];

      supabase.from().select().eq().order().range.mockResolvedValueOnce({
        data: mockProducts,
        error: null,
        count: 1,
      });

      const response = await request(app)
        .get('/products?region=Central')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data[0].region).toBe('Central');
    });

    it('should filter products by price range', async () => {
      const mockProducts = [
        global.testUtils.createTestProduct({ price: 50000 }),
      ];

      supabase.from().select().gte().lte().order().range.mockResolvedValueOnce({
        data: mockProducts,
        error: null,
        count: 1,
      });

      const response = await request(app)
        .get('/products?minPrice=40000&maxPrice=60000')
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should search products by name', async () => {
      const mockProducts = [
        global.testUtils.createTestProduct({ name: 'Fresh Matooke' }),
      ];

      supabase.from().select().ilike().order().range.mockResolvedValueOnce({
        data: mockProducts,
        error: null,
        count: 1,
      });

      const response = await request(app)
        .get('/products?search=matooke')
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should paginate results', async () => {
      const mockProducts = Array.from({ length: 10 }, (_, i) =>
        global.testUtils.createTestProduct({ id: `${i + 1}` })
      );

      supabase.from().select().order().range.mockResolvedValueOnce({
        data: mockProducts,
        error: null,
        count: 50,
      });

      const response = await request(app)
        .get('/products?page=1&limit=10')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.total).toBe(50);
      expect(response.body.pagination.totalPages).toBe(5);
    });

    it('should sort products', async () => {
      const mockProducts = [
        global.testUtils.createTestProduct({ price: 30000 }),
        global.testUtils.createTestProduct({ price: 50000 }),
      ];

      supabase.from().select().order().range.mockResolvedValueOnce({
        data: mockProducts,
        error: null,
        count: 2,
      });

      const response = await request(app)
        .get('/products?sortBy=price&order=asc')
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });

  describe('GET /products/:id', () => {
    it('should return product details', async () => {
      const mockProduct = global.testUtils.createTestProduct();

      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: mockProduct,
        error: null,
      });

      const response = await request(app)
        .get('/products/test-product-id')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe('test-product-id');
    });

    it('should return 404 for non-existent product', async () => {
      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: null,
        error: { code: 'PGRST116' },
      });

      const response = await request(app)
        .get('/products/non-existent-id')
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('NOT_FOUND');
    });
  });

  describe('POST /products', () => {
    beforeEach(() => {
      // Set up farmer user for create operations
      jest.spyOn(require('../../src/middleware/authMiddleware'), 'authenticate')
        .mockImplementation((req, res, next) => {
          req.user = global.testUtils.createTestFarmer();
          next();
        });
    });

    it('should create a new product', async () => {
      const productData = {
        name: 'Fresh Matooke',
        description: 'Fresh matooke from our farm',
        price: 35000,
        unit: 'bunch',
        category: 'fruits_vegetables',
        stock: 50,
        isOrganic: true,
      };

      const mockProduct = global.testUtils.createTestProduct(productData);

      supabase.from().insert().select().single.mockResolvedValueOnce({
        data: mockProduct,
        error: null,
      });

      const response = await request(app)
        .post('/products')
        .send(productData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('created');
      expect(response.body.data.name).toBe('Fresh Matooke');
    });

    it('should fail with missing required fields', async () => {
      const productData = {
        name: 'Incomplete Product',
        // Missing price, unit, category, stock
      };

      const response = await request(app)
        .post('/products')
        .send(productData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should fail with invalid price', async () => {
      const productData = {
        name: 'Test Product',
        description: 'Description',
        price: -1000, // Invalid negative price
        unit: 'kg',
        category: 'grains',
        stock: 10,
      };

      const response = await request(app)
        .post('/products')
        .send(productData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('PUT /products/:id', () => {
    beforeEach(() => {
      jest.spyOn(require('../../src/middleware/authMiddleware'), 'authenticate')
        .mockImplementation((req, res, next) => {
          req.user = global.testUtils.createTestFarmer();
          next();
        });
    });

    it('should update a product', async () => {
      const updateData = {
        price: 40000,
        stock: 30,
      };

      const mockProduct = global.testUtils.createTestProduct(updateData);

      // Mock ownership check
      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: { farmerId: 'test-farmer-id' },
        error: null,
      });

      // Mock update
      supabase.from().update().eq().select().single.mockResolvedValueOnce({
        data: mockProduct,
        error: null,
      });

      const response = await request(app)
        .put('/products/test-product-id')
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('updated');
    });

    it('should fail when not product owner', async () => {
      // Mock ownership check - different farmer
      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: { farmerId: 'different-farmer-id' },
        error: null,
      });

      const response = await request(app)
        .put('/products/test-product-id')
        .send({ price: 40000 })
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('FORBIDDEN');
    });
  });

  describe('DELETE /products/:id', () => {
    beforeEach(() => {
      jest.spyOn(require('../../src/middleware/authMiddleware'), 'authenticate')
        .mockImplementation((req, res, next) => {
          req.user = global.testUtils.createTestFarmer();
          next();
        });
    });

    it('should delete a product', async () => {
      // Mock ownership check
      supabase.from().select().eq().single.mockResolvedValueOnce({
        data: { farmerId: 'test-farmer-id' },
        error: null,
      });

      // Mock delete
      supabase.from().delete().eq.mockResolvedValueOnce({
        data: null,
        error: null,
      });

      const response = await request(app)
        .delete('/products/test-product-id')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('deleted');
    });
  });

  describe('POST /products/:id/favorite', () => {
    it('should add product to favorites', async () => {
      supabase.from().insert.mockResolvedValueOnce({
        data: null,
        error: null,
      });

      const response = await request(app)
        .post('/products/test-product-id/favorite')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('favorites');
    });

    it('should handle already favorited product', async () => {
      supabase.from().insert.mockResolvedValueOnce({
        data: null,
        error: { code: '23505' }, // Unique violation
      });

      const response = await request(app)
        .post('/products/test-product-id/favorite')
        .expect(409);

      expect(response.body.success).toBe(false);
    });
  });

  describe('DELETE /products/:id/favorite', () => {
    it('should remove product from favorites', async () => {
      supabase.from().delete().eq().eq.mockResolvedValueOnce({
        data: null,
        error: null,
      });

      const response = await request(app)
        .delete('/products/test-product-id/favorite')
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });

  describe('GET /products/:id/reviews', () => {
    it('should return product reviews', async () => {
      const mockReviews = [
        {
          id: 'review-1',
          rating: 5,
          comment: 'Great product!',
          userId: 'user-1',
          createdAt: new Date().toISOString(),
        },
      ];

      supabase.from().select().eq().order().range.mockResolvedValueOnce({
        data: mockReviews,
        error: null,
        count: 1,
      });

      const response = await request(app)
        .get('/products/test-product-id/reviews')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
    });
  });

  describe('POST /products/:id/reviews', () => {
    it('should add a review', async () => {
      const reviewData = {
        rating: 5,
        comment: 'Excellent quality!',
      };

      supabase.from().insert().select().single.mockResolvedValueOnce({
        data: { id: 'new-review-id', ...reviewData },
        error: null,
      });

      const response = await request(app)
        .post('/products/test-product-id/reviews')
        .send(reviewData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.rating).toBe(5);
    });

    it('should fail with invalid rating', async () => {
      const reviewData = {
        rating: 6, // Invalid - should be 1-5
        comment: 'Test review',
      };

      const response = await request(app)
        .post('/products/test-product-id/reviews')
        .send(reviewData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });
});
