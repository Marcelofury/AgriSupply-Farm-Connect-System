const { supabase, uploadFile, deleteFile } = require('../config/supabase');
const { ApiError, asyncHandler } = require('../middleware/errorMiddleware');
const { sanitizeUser, paginate, paginationResponse, formatPhoneNumber } = require('../utils/helpers');
const { processFile } = require('../middleware/uploadMiddleware');
const logger = require('../utils/logger');

/**
 * @desc    Get current user profile
 * @route   GET /api/v1/users/profile
 */
const getProfile = asyncHandler(async (req, res) => {
  res.json({
    success: true,
    data: sanitizeUser(req.user),
  });
});

/**
 * @desc    Update current user profile
 * @route   PUT /api/v1/users/profile
 */
const updateProfile = asyncHandler(async (req, res) => {
  const { fullName, phone, region, district, bio } = req.body;
  const userId = req.user.id;

  const updates = {
    updated_at: new Date().toISOString(),
  };

  if (fullName) updates.full_name = fullName;
  if (phone) updates.phone = formatPhoneNumber(phone);
  if (region) updates.region = region;
  if (district) updates.district = district;
  if (bio !== undefined) updates.bio = bio;

  const { data, error } = await supabase
    .from('users')
    .update(updates)
    .eq('id', userId)
    .select()
    .single();

  if (error) {
    logger.error('Update profile error:', error);
    throw new ApiError(400, 'Failed to update profile');
  }

  res.json({
    success: true,
    message: 'Profile updated successfully',
    data: sanitizeUser(data),
  });
});

/**
 * @desc    Upload profile photo
 * @route   POST /api/v1/users/profile/photo
 */
const uploadPhoto = asyncHandler(async (req, res) => {
  if (!req.file) {
    throw new ApiError(400, 'No file uploaded');
  }

  const userId = req.user.id;
  const fileInfo = processFile(req.file, 'avatars');

  // Delete old photo if exists
  if (req.user.avatar_url) {
    const oldPath = req.user.avatar_url.split('/').pop();
    await deleteFile('avatars', oldPath);
  }

  // Upload new photo
  const uploadResult = await uploadFile(
    fileInfo.buffer,
    'avatars',
    fileInfo.filePath,
    fileInfo.contentType
  );

  if (!uploadResult.success) {
    throw new ApiError(400, 'Failed to upload photo');
  }

  // Update user profile
  const { data, error } = await supabase
    .from('users')
    .update({
      avatar_url: uploadResult.publicUrl,
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId)
    .select()
    .single();

  if (error) {
    logger.error('Update avatar error:', error);
    throw new ApiError(400, 'Failed to update profile photo');
  }

  res.json({
    success: true,
    message: 'Photo uploaded successfully',
    data: {
      avatarUrl: uploadResult.publicUrl,
    },
  });
});

/**
 * @desc    Delete profile photo
 * @route   DELETE /api/v1/users/profile/photo
 */
const deletePhoto = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  if (req.user.avatar_url) {
    const oldPath = req.user.avatar_url.split('/').pop();
    await deleteFile('avatars', oldPath);
  }

  const { error } = await supabase
    .from('users')
    .update({
      avatar_url: null,
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId);

  if (error) {
    logger.error('Delete avatar error:', error);
    throw new ApiError(400, 'Failed to delete photo');
  }

  res.json({
    success: true,
    message: 'Photo deleted successfully',
  });
});

/**
 * @desc    Update user address
 * @route   PUT /api/v1/users/address
 */
const updateAddress = asyncHandler(async (req, res) => {
  const { region, district, address, landmark, coordinates } = req.body;
  const userId = req.user.id;

  const { data, error } = await supabase
    .from('users')
    .update({
      region,
      district,
      address,
      landmark,
      coordinates,
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId)
    .select()
    .single();

  if (error) {
    logger.error('Update address error:', error);
    throw new ApiError(400, 'Failed to update address');
  }

  res.json({
    success: true,
    message: 'Address updated successfully',
    data: sanitizeUser(data),
  });
});

/**
 * @desc    Get list of farmers
 * @route   GET /api/v1/users/farmers
 */
const getFarmers = asyncHandler(async (req, res) => {
  const { page, limit, region, isVerified, search } = req.query;
  const { page: pageNum, limit: limitNum, offset } = paginate(page, limit);

  let query = supabase
    .from('users')
    .select('id, full_name, avatar_url, region, district, bio, is_verified, rating, total_sales, created_at', { count: 'exact' })
    .eq('role', 'farmer')
    .eq('is_suspended', false);

  if (region) {
    query = query.eq('region', region);
  }

  if (isVerified === 'true') {
    query = query.eq('is_verified', true);
  }

  if (search) {
    query = query.ilike('full_name', `%${search}%`);
  }

  const { data, count, error } = await query
    .order('rating', { ascending: false })
    .range(offset, offset + limitNum - 1);

  if (error) {
    logger.error('Get farmers error:', error);
    throw new ApiError(400, 'Failed to fetch farmers');
  }

  res.json({
    success: true,
    ...paginationResponse(data, count, pageNum, limitNum),
  });
});

/**
 * @desc    Get farmer profile by ID
 * @route   GET /api/v1/users/farmers/:id
 */
const getFarmerProfile = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const { data: farmer, error } = await supabase
    .from('users')
    .select('id, full_name, avatar_url, region, district, bio, is_verified, rating, total_sales, created_at')
    .eq('id', id)
    .eq('role', 'farmer')
    .single();

  if (error || !farmer) {
    throw new ApiError(404, 'Farmer not found');
  }

  // Get farmer's products
  const { data: products } = await supabase
    .from('products')
    .select('id, name, images, price, unit, category, rating')
    .eq('farmer_id', id)
    .eq('is_active', true)
    .limit(10);

  // Get follower count
  const { count: followerCount } = await supabase
    .from('farmer_followers')
    .select('*', { count: 'exact', head: true })
    .eq('farmer_id', id);

  // Check if current user follows this farmer
  let isFollowing = false;
  if (req.user) {
    const { data: follow } = await supabase
      .from('farmer_followers')
      .select('id')
      .eq('farmer_id', id)
      .eq('follower_id', req.user.id)
      .single();
    isFollowing = !!follow;
  }

  res.json({
    success: true,
    data: {
      ...farmer,
      products,
      followerCount,
      isFollowing,
    },
  });
});

/**
 * @desc    Follow a farmer
 * @route   POST /api/v1/users/farmers/:id/follow
 */
const followFarmer = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  if (id === userId) {
    throw new ApiError(400, 'You cannot follow yourself');
  }

  // Check if farmer exists
  const { data: farmer } = await supabase
    .from('users')
    .select('id')
    .eq('id', id)
    .eq('role', 'farmer')
    .single();

  if (!farmer) {
    throw new ApiError(404, 'Farmer not found');
  }

  // Check if already following
  const { data: existing } = await supabase
    .from('farmer_followers')
    .select('id')
    .eq('farmer_id', id)
    .eq('follower_id', userId)
    .single();

  if (existing) {
    throw new ApiError(400, 'Already following this farmer');
  }

  const { error } = await supabase.from('farmer_followers').insert({
    farmer_id: id,
    follower_id: userId,
    created_at: new Date().toISOString(),
  });

  if (error) {
    logger.error('Follow farmer error:', error);
    throw new ApiError(400, 'Failed to follow farmer');
  }

  res.json({
    success: true,
    message: 'Successfully followed farmer',
  });
});

/**
 * @desc    Unfollow a farmer
 * @route   DELETE /api/v1/users/farmers/:id/follow
 */
const unfollowFarmer = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const { error } = await supabase
    .from('farmer_followers')
    .delete()
    .eq('farmer_id', id)
    .eq('follower_id', userId);

  if (error) {
    logger.error('Unfollow farmer error:', error);
    throw new ApiError(400, 'Failed to unfollow farmer');
  }

  res.json({
    success: true,
    message: 'Successfully unfollowed farmer',
  });
});

/**
 * @desc    Get list of followed farmers
 * @route   GET /api/v1/users/following
 */
const getFollowing = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { page, limit } = req.query;
  const { page: pageNum, limit: limitNum, offset } = paginate(page, limit);

  const { data, count, error } = await supabase
    .from('farmer_followers')
    .select(`
      farmer:farmer_id (
        id, full_name, avatar_url, region, district, bio, is_verified, rating
      )
    `, { count: 'exact' })
    .eq('follower_id', userId)
    .range(offset, offset + limitNum - 1);

  if (error) {
    logger.error('Get following error:', error);
    throw new ApiError(400, 'Failed to fetch following');
  }

  const farmers = data.map(item => item.farmer);

  res.json({
    success: true,
    ...paginationResponse(farmers, count, pageNum, limitNum),
  });
});

/**
 * @desc    Get list of followers (for farmers)
 * @route   GET /api/v1/users/followers
 */
const getFollowers = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { page, limit } = req.query;
  const { page: pageNum, limit: limitNum, offset } = paginate(page, limit);

  const { data, count, error } = await supabase
    .from('farmer_followers')
    .select(`
      follower:follower_id (
        id, full_name, avatar_url, region
      )
    `, { count: 'exact' })
    .eq('farmer_id', userId)
    .range(offset, offset + limitNum - 1);

  if (error) {
    logger.error('Get followers error:', error);
    throw new ApiError(400, 'Failed to fetch followers');
  }

  const followers = data.map(item => item.follower);

  res.json({
    success: true,
    ...paginationResponse(followers, count, pageNum, limitNum),
  });
});

/**
 * @desc    Get user statistics
 * @route   GET /api/v1/users/statistics
 */
const getStatistics = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const isFarmer = req.user.role === 'farmer';

  let stats = {};

  if (isFarmer) {
    // Farmer statistics
    const { count: productCount } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true })
      .eq('farmer_id', userId);

    const { count: orderCount } = await supabase
      .from('order_items')
      .select('*', { count: 'exact', head: true })
      .eq('farmer_id', userId);

    const { count: followerCount } = await supabase
      .from('farmer_followers')
      .select('*', { count: 'exact', head: true })
      .eq('farmer_id', userId);

    const { data: salesData } = await supabase
      .from('order_items')
      .select('total')
      .eq('farmer_id', userId)
      .eq('status', 'delivered');

    const totalSales = salesData?.reduce((sum, item) => sum + item.total, 0) || 0;

    stats = {
      productCount,
      orderCount,
      followerCount,
      totalSales,
    };
  } else {
    // Buyer statistics
    const { count: orderCount } = await supabase
      .from('orders')
      .select('*', { count: 'exact', head: true })
      .eq('buyer_id', userId);

    const { count: followingCount } = await supabase
      .from('farmer_followers')
      .select('*', { count: 'exact', head: true })
      .eq('follower_id', userId);

    const { data: spendData } = await supabase
      .from('orders')
      .select('total')
      .eq('buyer_id', userId)
      .eq('payment_status', 'completed');

    const totalSpent = spendData?.reduce((sum, item) => sum + item.total, 0) || 0;

    stats = {
      orderCount,
      followingCount,
      totalSpent,
    };
  }

  res.json({
    success: true,
    data: stats,
  });
});

module.exports = {
  getProfile,
  updateProfile,
  uploadPhoto,
  deletePhoto,
  updateAddress,
  getFarmers,
  getFarmerProfile,
  followFarmer,
  unfollowFarmer,
  getFollowing,
  getFollowers,
  getStatistics,
};
