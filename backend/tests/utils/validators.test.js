/**
 * Validation Helper Tests
 * Tests for input validation utilities
 */

const {
  validateEmail,
  validatePhone,
  validatePassword,
  validateUgandanPhone,
  validatePrice,
  validateQuantity,
  sanitizeInput,
  validateOrderStatus,
  validatePaymentMethod,
  validateCategory,
  validateRegion,
} = require('../../src/utils/validators');

describe('Validators', () => {
  describe('validateEmail', () => {
    it('should accept valid email addresses', () => {
      expect(validateEmail('test@example.com')).toBe(true);
      expect(validateEmail('user.name@domain.co.ug')).toBe(true);
      expect(validateEmail('user+tag@gmail.com')).toBe(true);
      expect(validateEmail('a@b.co')).toBe(true);
    });

    it('should reject invalid email addresses', () => {
      expect(validateEmail('')).toBe(false);
      expect(validateEmail('invalid')).toBe(false);
      expect(validateEmail('invalid@')).toBe(false);
      expect(validateEmail('@domain.com')).toBe(false);
      expect(validateEmail('user@.com')).toBe(false);
      expect(validateEmail('user@domain')).toBe(false);
      expect(validateEmail(null)).toBe(false);
      expect(validateEmail(undefined)).toBe(false);
    });
  });

  describe('validatePhone', () => {
    it('should accept valid phone numbers', () => {
      expect(validatePhone('+256701234567')).toBe(true);
      expect(validatePhone('+256771234567')).toBe(true);
      expect(validatePhone('+256781234567')).toBe(true);
      expect(validatePhone('+256751234567')).toBe(true);
      expect(validatePhone('+256391234567')).toBe(true);
    });

    it('should reject invalid phone numbers', () => {
      expect(validatePhone('')).toBe(false);
      expect(validatePhone('0701234567')).toBe(false); // Missing country code
      expect(validatePhone('+254701234567')).toBe(false); // Wrong country
      expect(validatePhone('+25670123456')).toBe(false); // Too short
      expect(validatePhone('+2567012345678')).toBe(false); // Too long
      expect(validatePhone('invalid')).toBe(false);
    });
  });

  describe('validateUgandanPhone', () => {
    it('should accept valid Ugandan phone formats', () => {
      // MTN Uganda
      expect(validateUgandanPhone('+256771234567')).toBe(true);
      expect(validateUgandanPhone('+256781234567')).toBe(true);
      expect(validateUgandanPhone('+256761234567')).toBe(true);
      
      // Airtel Uganda
      expect(validateUgandanPhone('+256701234567')).toBe(true);
      expect(validateUgandanPhone('+256751234567')).toBe(true);
      
      // Uganda Telecom
      expect(validateUgandanPhone('+256411234567')).toBe(true);
    });

    it('should reject non-Ugandan numbers', () => {
      expect(validateUgandanPhone('+254701234567')).toBe(false); // Kenya
      expect(validateUgandanPhone('+255701234567')).toBe(false); // Tanzania
      expect(validateUgandanPhone('+1234567890')).toBe(false); // Invalid
    });
  });

  describe('validatePassword', () => {
    it('should accept strong passwords', () => {
      expect(validatePassword('Password123!')).toBe(true);
      expect(validatePassword('MySecure@Pass1')).toBe(true);
      expect(validatePassword('Str0ng#Password')).toBe(true);
      expect(validatePassword('12345678Aa@')).toBe(true);
    });

    it('should reject weak passwords', () => {
      expect(validatePassword('')).toBe(false);
      expect(validatePassword('short')).toBe(false); // Too short
      expect(validatePassword('password')).toBe(false); // No uppercase/number
      expect(validatePassword('PASSWORD')).toBe(false); // No lowercase/number
      expect(validatePassword('Password')).toBe(false); // No number
      expect(validatePassword('password123')).toBe(false); // No uppercase
      expect(validatePassword('PASSWORD123')).toBe(false); // No lowercase
    });

    it('should provide password strength feedback', () => {
      const result = validatePassword('weak', { returnDetails: true });
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Password must be at least 8 characters');
    });
  });

  describe('validatePrice', () => {
    it('should accept valid prices', () => {
      expect(validatePrice(1000)).toBe(true);
      expect(validatePrice(50000)).toBe(true);
      expect(validatePrice(1)).toBe(true);
      expect(validatePrice(999999999)).toBe(true);
    });

    it('should reject invalid prices', () => {
      expect(validatePrice(0)).toBe(false);
      expect(validatePrice(-1000)).toBe(false);
      expect(validatePrice('invalid')).toBe(false);
      expect(validatePrice(null)).toBe(false);
      expect(validatePrice(undefined)).toBe(false);
      expect(validatePrice(NaN)).toBe(false);
    });
  });

  describe('validateQuantity', () => {
    it('should accept valid quantities', () => {
      expect(validateQuantity(1)).toBe(true);
      expect(validateQuantity(100)).toBe(true);
      expect(validateQuantity(1000)).toBe(true);
    });

    it('should reject invalid quantities', () => {
      expect(validateQuantity(0)).toBe(false);
      expect(validateQuantity(-5)).toBe(false);
      expect(validateQuantity(1.5)).toBe(false); // Decimal not allowed
      expect(validateQuantity('invalid')).toBe(false);
      expect(validateQuantity(null)).toBe(false);
    });
  });

  describe('sanitizeInput', () => {
    it('should trim whitespace', () => {
      expect(sanitizeInput('  hello  ')).toBe('hello');
      expect(sanitizeInput('\n\ntest\n\n')).toBe('test');
    });

    it('should escape HTML entities', () => {
      expect(sanitizeInput('<script>alert("xss")</script>')).toBe('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;');
      expect(sanitizeInput('Test & Demo')).toBe('Test &amp; Demo');
    });

    it('should handle special characters', () => {
      expect(sanitizeInput("O'Brien")).toBe("O&#39;Brien");
    });

    it('should handle empty/null input', () => {
      expect(sanitizeInput('')).toBe('');
      expect(sanitizeInput(null)).toBe('');
      expect(sanitizeInput(undefined)).toBe('');
    });
  });

  describe('validateOrderStatus', () => {
    it('should accept valid order statuses', () => {
      expect(validateOrderStatus('pending')).toBe(true);
      expect(validateOrderStatus('confirmed')).toBe(true);
      expect(validateOrderStatus('processing')).toBe(true);
      expect(validateOrderStatus('shipped')).toBe(true);
      expect(validateOrderStatus('delivered')).toBe(true);
      expect(validateOrderStatus('cancelled')).toBe(true);
    });

    it('should reject invalid order statuses', () => {
      expect(validateOrderStatus('invalid')).toBe(false);
      expect(validateOrderStatus('PENDING')).toBe(false); // Case sensitive
      expect(validateOrderStatus('')).toBe(false);
      expect(validateOrderStatus(null)).toBe(false);
    });
  });

  describe('validatePaymentMethod', () => {
    it('should accept valid payment methods', () => {
      expect(validatePaymentMethod('mtn_mobile_money')).toBe(true);
      expect(validatePaymentMethod('airtel_money')).toBe(true);
      expect(validatePaymentMethod('card')).toBe(true);
      expect(validatePaymentMethod('cash_on_delivery')).toBe(true);
    });

    it('should reject invalid payment methods', () => {
      expect(validatePaymentMethod('paypal')).toBe(false);
      expect(validatePaymentMethod('bitcoin')).toBe(false);
      expect(validatePaymentMethod('')).toBe(false);
      expect(validatePaymentMethod(null)).toBe(false);
    });
  });

  describe('validateCategory', () => {
    it('should accept valid product categories', () => {
      expect(validateCategory('fruits_vegetables')).toBe(true);
      expect(validateCategory('grains_cereals')).toBe(true);
      expect(validateCategory('dairy_eggs')).toBe(true);
      expect(validateCategory('meat_poultry')).toBe(true);
      expect(validateCategory('fish_seafood')).toBe(true);
      expect(validateCategory('herbs_spices')).toBe(true);
      expect(validateCategory('beverages')).toBe(true);
      expect(validateCategory('processed_foods')).toBe(true);
      expect(validateCategory('seeds_seedlings')).toBe(true);
      expect(validateCategory('farm_equipment')).toBe(true);
    });

    it('should reject invalid categories', () => {
      expect(validateCategory('electronics')).toBe(false);
      expect(validateCategory('clothing')).toBe(false);
      expect(validateCategory('')).toBe(false);
      expect(validateCategory(null)).toBe(false);
    });
  });

  describe('validateRegion', () => {
    it('should accept valid Ugandan regions', () => {
      expect(validateRegion('Central')).toBe(true);
      expect(validateRegion('Eastern')).toBe(true);
      expect(validateRegion('Western')).toBe(true);
      expect(validateRegion('Northern')).toBe(true);
    });

    it('should reject invalid regions', () => {
      expect(validateRegion('Nairobi')).toBe(false);
      expect(validateRegion('Southern')).toBe(false);
      expect(validateRegion('')).toBe(false);
      expect(validateRegion(null)).toBe(false);
    });
  });
});

describe('Complex Validation Scenarios', () => {
  it('should validate complete user registration data', () => {
    const userData = {
      email: 'test@example.com',
      password: 'SecurePass123!',
      phone: '+256771234567',
      fullName: 'John Doe',
      region: 'Central',
    };

    expect(validateEmail(userData.email)).toBe(true);
    expect(validatePassword(userData.password)).toBe(true);
    expect(validateUgandanPhone(userData.phone)).toBe(true);
    expect(validateRegion(userData.region)).toBe(true);
  });

  it('should validate complete product data', () => {
    const productData = {
      name: 'Fresh Matooke',
      price: 35000,
      category: 'fruits_vegetables',
      quantity: 50,
    };

    expect(sanitizeInput(productData.name)).toBe('Fresh Matooke');
    expect(validatePrice(productData.price)).toBe(true);
    expect(validateCategory(productData.category)).toBe(true);
    expect(validateQuantity(productData.quantity)).toBe(true);
  });

  it('should validate order data', () => {
    const orderData = {
      status: 'pending',
      paymentMethod: 'mtn_mobile_money',
      items: [
        { productId: 'p1', quantity: 2 },
        { productId: 'p2', quantity: 1 },
      ],
    };

    expect(validateOrderStatus(orderData.status)).toBe(true);
    expect(validatePaymentMethod(orderData.paymentMethod)).toBe(true);
    orderData.items.forEach((item) => {
      expect(validateQuantity(item.quantity)).toBe(true);
    });
  });
});
