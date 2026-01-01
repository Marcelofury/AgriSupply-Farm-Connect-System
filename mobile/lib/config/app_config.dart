class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Backend API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/api';

  // App Information
  static const String appName = 'AgriSupply Farm Connect';
  static const String appVersion = '1.0.0';

  // Mobile Money Configuration
  static const String mobileMoneyApiUrl = 'YOUR_MOBILE_MONEY_API_URL';
  static const String mobileMoneyApiKey = 'YOUR_MOBILE_MONEY_API_KEY';

  // AI Service Configuration
  static const String aiServiceUrl = 'YOUR_AI_SERVICE_URL';
  static const String aiServiceKey = 'YOUR_AI_SERVICE_KEY';

  // Default pagination
  static const int defaultPageSize = 20;

  // Image upload limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxImagesPerProduct = 5;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
