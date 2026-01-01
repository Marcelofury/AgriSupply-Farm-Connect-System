// App configuration constants
module.exports = {
  // API Configuration
  api: {
    version: process.env.API_VERSION || 'v1',
    prefix: '/api',
  },

  // JWT Configuration
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  },

  // Rate Limiting
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  },

  // File Upload
  upload: {
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE) || 5 * 1024 * 1024, // 5MB
    allowedTypes: (process.env.ALLOWED_FILE_TYPES || 'image/jpeg,image/png,image/webp').split(','),
    productImagesPath: 'products',
    profilePhotosPath: 'avatars',
    documentsPath: 'documents',
  },

  // Uganda-specific configuration
  uganda: {
    regions: ['Central', 'Eastern', 'Northern', 'Western'],
    districts: {
      Central: ['Kampala', 'Wakiso', 'Mukono', 'Luwero', 'Masaka', 'Mpigi', 'Mityana', 'Kayunga', 'Buikwe', 'Kalungu'],
      Eastern: ['Jinja', 'Mbale', 'Soroti', 'Tororo', 'Iganga', 'Busia', 'Kamuli', 'Bugiri', 'Pallisa', 'Kumi'],
      Northern: ['Gulu', 'Lira', 'Arua', 'Kitgum', 'Apac', 'Nebbi', 'Moroto', 'Kotido', 'Adjumani', 'Moyo'],
      Western: ['Mbarara', 'Kabale', 'Fort Portal', 'Kasese', 'Hoima', 'Masindi', 'Bushenyi', 'Rukungiri', 'Kyenjojo', 'Ntungamo'],
    },
    currency: {
      code: 'UGX',
      symbol: 'USh',
      name: 'Ugandan Shilling',
    },
    phonePrefix: '+256',
    mobileMoneyPrefixes: {
      mtn: ['77', '78', '76'],
      airtel: ['70', '75', '74'],
    },
  },

  // Product Categories
  productCategories: [
    { id: 'vegetables', name: 'Vegetables', icon: '🥬' },
    { id: 'fruits', name: 'Fruits', icon: '🍎' },
    { id: 'grains', name: 'Grains & Cereals', icon: '🌾' },
    { id: 'legumes', name: 'Legumes', icon: '🫘' },
    { id: 'tubers', name: 'Tubers & Roots', icon: '🥔' },
    { id: 'dairy', name: 'Dairy & Eggs', icon: '🥛' },
    { id: 'meat', name: 'Meat & Poultry', icon: '🍖' },
    { id: 'fish', name: 'Fish & Seafood', icon: '🐟' },
    { id: 'spices', name: 'Spices & Herbs', icon: '🌿' },
    { id: 'coffee', name: 'Coffee & Tea', icon: '☕' },
    { id: 'other', name: 'Other', icon: '📦' },
  ],

  // Order Status
  orderStatuses: [
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'out_for_delivery',
    'delivered',
    'cancelled',
    'refunded',
  ],

  // Payment Statuses
  paymentStatuses: [
    'pending',
    'processing',
    'completed',
    'failed',
    'refunded',
    'cancelled',
  ],

  // User Roles
  userRoles: ['buyer', 'farmer', 'admin'],

  // Premium Features
  premium: {
    monthlyPrice: 50000, // UGX
    yearlyPrice: 500000, // UGX
    features: [
      'AI Farming Assistant',
      'Priority Product Listings',
      'Advanced Analytics',
      'Bulk Upload',
      'Custom Branding',
      'Priority Support',
      'Market Predictions',
      'Export Reports',
    ],
  },

  // Notification Types
  notificationTypes: [
    'order_placed',
    'order_confirmed',
    'order_shipped',
    'order_delivered',
    'order_cancelled',
    'payment_received',
    'payment_failed',
    'new_message',
    'price_alert',
    'promotion',
    'farming_tip',
    'weather_alert',
    'system',
  ],

  // AI Configuration
  ai: {
    model: process.env.OPENAI_MODEL || 'gpt-4',
    maxTokens: 1000,
    temperature: 0.7,
    systemPrompt: `You are an AI farming assistant for AgriSupply, helping Ugandan farmers with:
- Crop management and best practices
- Pest and disease identification
- Weather-based recommendations
- Market pricing insights
- Sustainable farming techniques

Always provide practical, actionable advice specific to Uganda's climate and conditions.
Be concise and helpful. If you're unsure, recommend consulting a local agricultural extension officer.`,
  },

  // Pagination
  pagination: {
    defaultLimit: 20,
    maxLimit: 100,
  },

  // Cache TTL (in seconds)
  cache: {
    products: 300, // 5 minutes
    categories: 3600, // 1 hour
    userProfile: 600, // 10 minutes
  },
};
