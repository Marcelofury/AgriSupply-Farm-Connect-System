const productController = require('../../src/controllers/productController');
const { supabase } = require('../../src/config/supabase');

describe('Product visibility filters', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  function buildReq(query = {}) {
    return { query };
  }

  function buildRes() {
    return {
      json: jest.fn(),
    };
  }

  it('does not apply farmer region filter when region is not provided', async () => {
    const queryBuilder = {
      eq: jest.fn().mockReturnThis(),
      gte: jest.fn().mockReturnThis(),
      lte: jest.fn().mockReturnThis(),
      order: jest.fn().mockReturnThis(),
      range: jest.fn().mockResolvedValue({ data: [], count: 0, error: null }),
    };

    supabase.from = jest.fn().mockReturnValue({
      select: jest.fn().mockReturnValue(queryBuilder),
    });

    const req = buildReq({});
    const res = buildRes();

    await productController.getProducts(req, res, jest.fn());

    expect(queryBuilder.eq).toHaveBeenCalledWith('status', 'active');
    expect(queryBuilder.eq).not.toHaveBeenCalledWith('farmer.region', expect.anything());
  });

  it('applies farmer region filter only when region is provided', async () => {
    const queryBuilder = {
      eq: jest.fn().mockReturnThis(),
      gte: jest.fn().mockReturnThis(),
      lte: jest.fn().mockReturnThis(),
      order: jest.fn().mockReturnThis(),
      range: jest.fn().mockResolvedValue({ data: [], count: 0, error: null }),
    };

    supabase.from = jest.fn().mockReturnValue({
      select: jest.fn().mockReturnValue(queryBuilder),
    });

    const req = buildReq({ region: 'Central' });
    const res = buildRes();

    await productController.getProducts(req, res, jest.fn());

    expect(queryBuilder.eq).toHaveBeenCalledWith('status', 'active');
    expect(queryBuilder.eq).toHaveBeenCalledWith('farmer.region', 'Central');
  });
});
