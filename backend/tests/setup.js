/**
 * Test Setup File
 * Configures the test environment before running tests
 */

const { createClient } = require('@supabase/supabase-js');

// Mock environment variables
process.env.NODE_ENV = 'test';
process.env.PORT = '3001';
process.env.JWT_SECRET = 'test-jwt-secret-key-for-testing';
process.env.JWT_EXPIRES_IN = '1h';
process.env.SUPABASE_URL = 'https://test.supabase.co';
process.env.SUPABASE_ANON_KEY = 'test-anon-key';
process.env.SUPABASE_SERVICE_KEY = 'test-service-key';
process.env.OPENAI_API_KEY = 'test-openai-key';
process.env.MTN_API_KEY = 'test-mtn-key';
process.env.MTN_API_SECRET = 'test-mtn-secret';
process.env.AIRTEL_API_KEY = 'test-airtel-key';
process.env.AIRTEL_API_SECRET = 'test-airtel-secret';
process.env.FLUTTERWAVE_PUBLIC_KEY = 'test-flw-public';
process.env.FLUTTERWAVE_SECRET_KEY = 'test-flw-secret';

// Mock Supabase client
jest.mock('@supabase/supabase-js', () => ({
  createClient: jest.fn(() => ({
    from: jest.fn(() => ({
      select: jest.fn().mockReturnThis(),
      insert: jest.fn().mockReturnThis(),
      update: jest.fn().mockReturnThis(),
      delete: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      neq: jest.fn().mockReturnThis(),
      gt: jest.fn().mockReturnThis(),
      gte: jest.fn().mockReturnThis(),
      lt: jest.fn().mockReturnThis(),
      lte: jest.fn().mockReturnThis(),
      like: jest.fn().mockReturnThis(),
      ilike: jest.fn().mockReturnThis(),
      in: jest.fn().mockReturnThis(),
      order: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      range: jest.fn().mockReturnThis(),
      single: jest.fn().mockReturnThis(),
      maybeSingle: jest.fn().mockReturnThis(),
    })),
    auth: {
      signUp: jest.fn(),
      signInWithPassword: jest.fn(),
      signOut: jest.fn(),
      getUser: jest.fn(),
      admin: {
        createUser: jest.fn(),
        updateUserById: jest.fn(),
        deleteUser: jest.fn(),
        listUsers: jest.fn(),
      },
    },
    storage: {
      from: jest.fn(() => ({
        upload: jest.fn(),
        download: jest.fn(),
        remove: jest.fn(),
        getPublicUrl: jest.fn(() => ({
          data: { publicUrl: 'https://storage.test.com/image.jpg' },
        })),
      })),
    },
  })),
}));

// Mock OpenAI
jest.mock('openai', () => {
  return jest.fn().mockImplementation(() => ({
    chat: {
      completions: {
        create: jest.fn().mockResolvedValue({
          choices: [
            {
              message: {
                content: 'This is a test AI response.',
              },
            },
          ],
        }),
      },
    },
  }));
});

// Global test utilities
global.testUtils = {
  // Generate test user
  createTestUser: (overrides = {}) => ({
    id: 'test-user-id',
    email: 'test@example.com',
    fullName: 'Test User',
    phone: '+256701234567',
    role: 'buyer',
    region: 'Central',
    district: 'Kampala',
    isVerified: true,
    createdAt: new Date().toISOString(),
    ...overrides,
  }),

  // Generate test farmer
  createTestFarmer: (overrides = {}) => ({
    id: 'test-farmer-id',
    email: 'farmer@example.com',
    fullName: 'Test Farmer',
    phone: '+256701234568',
    role: 'farmer',
    region: 'Western',
    district: 'Mbarara',
    isVerified: true,
    rating: 4.5,
    createdAt: new Date().toISOString(),
    ...overrides,
  }),

  // Generate test product
  createTestProduct: (overrides = {}) => ({
    id: 'test-product-id',
    name: 'Test Product',
    description: 'Test product description',
    price: 50000,
    unit: 'kg',
    category: 'fruits_vegetables',
    stock: 100,
    farmerId: 'test-farmer-id',
    isOrganic: false,
    region: 'Central',
    district: 'Kampala',
    images: ['https://storage.test.com/product.jpg'],
    rating: 4.0,
    reviewCount: 10,
    createdAt: new Date().toISOString(),
    ...overrides,
  }),

  // Generate test order
  createTestOrder: (overrides = {}) => ({
    id: 'test-order-id',
    orderNumber: 'AGR-2024-TEST001',
    userId: 'test-user-id',
    status: 'pending',
    paymentStatus: 'pending',
    paymentMethod: 'mtn_mobile_money',
    subtotal: 100000,
    deliveryFee: 5000,
    total: 105000,
    deliveryAddress: 'Test Address, Kampala',
    createdAt: new Date().toISOString(),
    ...overrides,
  }),

  // Generate JWT token for testing
  generateTestToken: (userId = 'test-user-id', role = 'buyer') => {
    const jwt = require('jsonwebtoken');
    return jwt.sign(
      { userId, role },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
  },

  // Wait for async operations
  wait: (ms) => new Promise((resolve) => setTimeout(resolve, ms)),
};

// Clean up after all tests
afterAll(async () => {
  // Close any open connections
  jest.clearAllMocks();
});

// Reset mocks before each test
beforeEach(() => {
  jest.clearAllMocks();
});

// Console error/warn suppression for cleaner test output
const originalConsoleError = console.error;
const originalConsoleWarn = console.warn;

beforeAll(() => {
  console.error = (...args) => {
    if (
      args[0]?.includes?.('Warning:') ||
      args[0]?.includes?.('Error:')
    ) {
      return;
    }
    originalConsoleError.apply(console, args);
  };
  
  console.warn = (...args) => {
    if (args[0]?.includes?.('Warning:')) {
      return;
    }
    originalConsoleWarn.apply(console, args);
  };
});

afterAll(() => {
  console.error = originalConsoleError;
  console.warn = originalConsoleWarn;
});
