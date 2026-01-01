# AgriSupply Mobile App Documentation

Complete documentation for the AgriSupply Flutter mobile application.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [State Management](#state-management)
- [Navigation](#navigation)
- [API Integration](#api-integration)
- [Authentication Flow](#authentication-flow)
- [Payment Integration](#payment-integration)
- [Push Notifications](#push-notifications)
- [Offline Support](#offline-support)
- [Testing](#testing)

---

## Architecture Overview

AgriSupply follows Clean Architecture principles with Provider for state management.

```
┌─────────────────────────────────────────────────┐
│                  Presentation                    │
│        (Screens, Widgets, Providers)            │
├─────────────────────────────────────────────────┤
│                   Domain                         │
│            (Models, Use Cases)                   │
├─────────────────────────────────────────────────┤
│                    Data                          │
│         (Services, Repositories)                 │
├─────────────────────────────────────────────────┤
│                  External                        │
│      (Supabase, APIs, Local Storage)            │
└─────────────────────────────────────────────────┘
```

### Key Principles

1. **Separation of Concerns** - Each layer has specific responsibilities
2. **Dependency Injection** - Services injected via Provider
3. **Reactive UI** - State changes automatically update UI
4. **Error Handling** - Centralized error management
5. **Reusability** - Shared widgets and utilities

---

## Project Structure

```
lib/
├── config/
│   ├── app_config.dart      # App configuration
│   ├── theme.dart           # Material Design theme
│   └── routes.dart          # Navigation routes
│
├── models/
│   ├── user_model.dart      # User data model
│   ├── product_model.dart   # Product data model
│   ├── order_model.dart     # Order data model
│   ├── cart_model.dart      # Cart data model
│   ├── notification_model.dart
│   └── review_model.dart
│
├── providers/
│   ├── auth_provider.dart   # Authentication state
│   ├── product_provider.dart # Products state
│   ├── cart_provider.dart   # Shopping cart state
│   ├── order_provider.dart  # Orders state
│   ├── notification_provider.dart
│   └── theme_provider.dart  # Theme state
│
├── services/
│   ├── api_service.dart     # HTTP client
│   ├── auth_service.dart    # Auth API calls
│   ├── product_service.dart # Product API calls
│   ├── order_service.dart   # Order API calls
│   ├── payment_service.dart # Payment handling
│   ├── notification_service.dart
│   └── storage_service.dart # Local storage
│
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── otp_verification_screen.dart
│   │
│   ├── buyer/
│   │   ├── home_screen.dart
│   │   ├── product_list_screen.dart
│   │   ├── product_detail_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── checkout_screen.dart
│   │   ├── orders_screen.dart
│   │   ├── order_detail_screen.dart
│   │   └── profile_screen.dart
│   │
│   ├── farmer/
│   │   ├── farmer_dashboard_screen.dart
│   │   ├── my_products_screen.dart
│   │   ├── add_product_screen.dart
│   │   ├── farmer_orders_screen.dart
│   │   ├── earnings_screen.dart
│   │   └── farmer_profile_screen.dart
│   │
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart
│   │   ├── user_management_screen.dart
│   │   └── product_moderation_screen.dart
│   │
│   └── common/
│       └── notifications_screen.dart
│
├── widgets/
│   ├── product_card.dart
│   ├── cart_item_widget.dart
│   ├── order_card.dart
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── loading_widget.dart
│   ├── empty_state_widget.dart
│   └── rating_widget.dart
│
└── main.dart
```

---

## State Management

We use Provider for state management, following the MVVM pattern.

### Provider Setup

```dart
// main.dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const AgriSupplyApp(),
    ),
  );
}
```

### Provider Example

```dart
// providers/cart_provider.dart
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get itemCount => _items.length;
  
  double get total => _items.fold(
    0, (sum, item) => sum + (item.price * item.quantity)
  );

  Future<void> addToCart(Product product, int quantity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if already in cart
      final existingIndex = _items.indexWhere(
        (item) => item.productId == product.id
      );
      
      if (existingIndex >= 0) {
        _items[existingIndex].quantity += quantity;
      } else {
        _items.add(CartItem.fromProduct(product, quantity));
      }
      
      await _saveCart();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }
}
```

### Consuming Providers

```dart
// In widgets
class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        if (cart.isLoading) {
          return LoadingWidget();
        }
        
        if (cart.items.isEmpty) {
          return EmptyStateWidget(message: 'Your cart is empty');
        }
        
        return ListView.builder(
          itemCount: cart.itemCount,
          itemBuilder: (context, index) {
            return CartItemWidget(item: cart.items[index]);
          },
        );
      },
    );
  }
}
```

---

## Navigation

### Route Configuration

```dart
// config/routes.dart
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String productDetail = '/product/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetail = '/order/:id';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case productDetail:
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
```

### Navigation Usage

```dart
// Navigate to screen
Navigator.pushNamed(context, AppRoutes.productDetail, arguments: productId);

// Navigate and replace
Navigator.pushReplacementNamed(context, AppRoutes.home);

// Navigate and clear stack
Navigator.pushNamedAndRemoveUntil(
  context, 
  AppRoutes.login, 
  (route) => false,
);

// Go back
Navigator.pop(context);
```

---

## API Integration

### API Service

```dart
// services/api_service.dart
class ApiService {
  static const String baseUrl = 'https://api.agrisupply.ug/api/v1';
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
  ));

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired - try refresh
          final success = await _refreshToken();
          if (success) {
            return handler.resolve(await _retry(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return await _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  Future<Response> uploadFile(String path, File file, String fieldName) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(file.path),
    });
    return await _dio.post(path, data: formData);
  }
}
```

### Service Example

```dart
// services/product_service.dart
class ProductService {
  final ApiService _api = ApiService();

  Future<List<Product>> getProducts({
    String? category,
    String? region,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get('/products', params: {
      if (category != null) 'category': category,
      if (region != null) 'region': region,
      'page': page,
      'limit': limit,
    });
    
    final data = response.data['data'] as List;
    return data.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product> getProductById(String id) async {
    final response = await _api.get('/products/$id');
    return Product.fromJson(response.data['data']);
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final response = await _api.post('/products', data: productData);
    return Product.fromJson(response.data['data']);
  }

  Future<void> uploadProductImages(String productId, List<File> images) async {
    for (final image in images) {
      await _api.uploadFile('/products/$productId/images', image, 'images');
    }
  }
}
```

---

## Authentication Flow

### Auth Flow Diagram

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Splash    │────▶│  Check Auth  │────▶│    Home     │
│   Screen    │     │    State     │     │   Screen    │
└─────────────┘     └──────────────┘     └─────────────┘
                           │
                           │ Not authenticated
                           ▼
                    ┌──────────────┐
                    │  Onboarding  │
                    │   Screen     │
                    └──────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │    Login     │◀────────────┐
                    │   Screen     │             │
                    └──────────────┘             │
                      │         │                │
                      ▼         ▼                │
              ┌──────────┐  ┌──────────┐         │
              │  Email   │  │  Google  │         │
              │  Login   │  │  OAuth   │         │
              └──────────┘  └──────────┘         │
                      │         │                │
                      ▼         ▼                │
              ┌────────────────────┐             │
              │   Phone OTP        │             │
              │   Verification     │             │
              └────────────────────┘             │
                           │                     │
                           ▼                     │
                    ┌──────────────┐             │
                    │   Register   │─────────────┘
                    │   Screen     │
                    └──────────────┘
```

### Auth Provider

```dart
// providers/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isFarmer => _user?.role == 'farmer';
  bool get isAdmin => _user?.role == 'admin';

  Future<void> checkAuthState() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final token = await StorageService.getAccessToken();
      if (token != null) {
        // Validate token and get user
        final user = await AuthService.getCurrentUser();
        _user = user;
        _isAuthenticated = true;
      }
    } catch (e) {
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await AuthService.login(email, password);
      await StorageService.saveTokens(
        response.accessToken,
        response.refreshToken,
      );
      _user = response.user;
      _isAuthenticated = true;
      return true;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await StorageService.clearTokens();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
```

---

## Payment Integration

### Supported Payment Methods

| Method | Provider | Integration |
|--------|----------|-------------|
| MTN Mobile Money | MTN API | Native SDK |
| Airtel Money | Airtel API | Native SDK |
| Card Payments | Flutterwave | WebView |
| Cash on Delivery | N/A | Manual |

### Payment Flow

```dart
// services/payment_service.dart
class PaymentService {
  final ApiService _api = ApiService();

  Future<PaymentResult> initiatePayment({
    required String orderId,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    final response = await _api.post('/payments/initiate', data: {
      'orderId': orderId,
      'paymentMethod': paymentMethod,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    });
    
    return PaymentResult.fromJson(response.data['data']);
  }

  Future<PaymentStatus> checkPaymentStatus(String paymentId) async {
    final response = await _api.get('/payments/$paymentId/status');
    return PaymentStatus.fromJson(response.data['data']);
  }

  // For card payments - opens Flutterwave checkout
  Future<void> openCardPayment(String checkoutUrl) async {
    await launchUrl(Uri.parse(checkoutUrl));
  }
}
```

### Payment UI

```dart
// screens/buyer/checkout_screen.dart
class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedMethod = 'mtn_mobile_money';
  final _phoneController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    
    try {
      final cart = context.read<CartProvider>();
      final order = await context.read<OrderProvider>().createOrder(
        items: cart.items,
        deliveryAddress: _deliveryAddress,
        paymentMethod: _selectedMethod,
      );
      
      if (_selectedMethod == 'cash_on_delivery') {
        _showSuccess();
      } else {
        final result = await PaymentService().initiatePayment(
          orderId: order.id,
          paymentMethod: _selectedMethod,
          phoneNumber: _phoneController.text,
        );
        
        if (_selectedMethod == 'card') {
          await PaymentService().openCardPayment(result.checkoutUrl!);
        } else {
          // Mobile money - show waiting dialog
          _showPaymentPendingDialog(result.paymentId);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
```

---

## Push Notifications

### Firebase Setup

```dart
// services/notification_service.dart
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerDevice(token);
    }
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_registerDevice);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  static Future<void> _registerDevice(String token) async {
    await ApiService().post('/notifications/devices', data: {
      'deviceToken': token,
      'deviceType': Platform.isIOS ? 'ios' : 'android',
    });
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification
    FlutterLocalNotificationsPlugin().show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'agrisupply_channel',
          'AgriSupply',
          importance: Importance.high,
        ),
      ),
    );
  }
}
```

---

## Offline Support

### Local Storage

```dart
// services/storage_service.dart
class StorageService {
  static late SharedPreferences _prefs;
  static late Box _hiveBox;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await Hive.initFlutter();
    _hiveBox = await Hive.openBox('agrisupply');
  }

  // Token storage
  static Future<void> saveTokens(String access, String refresh) async {
    await _prefs.setString('accessToken', access);
    await _prefs.setString('refreshToken', refresh);
  }

  static Future<String?> getAccessToken() async {
    return _prefs.getString('accessToken');
  }

  // Cache products
  static Future<void> cacheProducts(List<Product> products) async {
    await _hiveBox.put('products', products.map((p) => p.toJson()).toList());
  }

  static List<Product>? getCachedProducts() {
    final data = _hiveBox.get('products');
    if (data == null) return null;
    return (data as List).map((json) => Product.fromJson(json)).toList();
  }
}
```

---

## Testing

### Unit Tests

```dart
// test/providers/cart_provider_test.dart
void main() {
  group('CartProvider', () {
    late CartProvider cart;

    setUp(() {
      cart = CartProvider();
    });

    test('starts with empty cart', () {
      expect(cart.items, isEmpty);
      expect(cart.total, 0);
    });

    test('adds item to cart', () async {
      final product = Product(id: '1', name: 'Test', price: 1000);
      await cart.addToCart(product, 2);
      
      expect(cart.itemCount, 1);
      expect(cart.total, 2000);
    });

    test('removes item from cart', () async {
      final product = Product(id: '1', name: 'Test', price: 1000);
      await cart.addToCart(product, 1);
      cart.removeFromCart('1');
      
      expect(cart.items, isEmpty);
    });
  });
}
```

### Widget Tests

```dart
// test/widgets/product_card_test.dart
void main() {
  testWidgets('ProductCard displays product info', (tester) async {
    final product = Product(
      id: '1',
      name: 'Fresh Matooke',
      price: 35000,
      unit: 'bunch',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProductCard(product: product),
      ),
    );

    expect(find.text('Fresh Matooke'), findsOneWidget);
    expect(find.text('UGX 35,000'), findsOneWidget);
    expect(find.text('per bunch'), findsOneWidget);
  });
}
```

### Integration Tests

```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full purchase flow', (tester) async {
    await tester.pumpWidget(AgriSupplyApp());
    await tester.pumpAndSettle();

    // Login
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    
    await tester.enterText(
      find.byKey(Key('email_field')), 
      'test@example.com'
    );
    await tester.enterText(
      find.byKey(Key('password_field')), 
      'password123'
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Browse products
    expect(find.text('Home'), findsOneWidget);
    
    // Add to cart
    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();

    // Verify cart
    await tester.tap(find.byIcon(Icons.shopping_cart));
    await tester.pumpAndSettle();
    expect(find.byType(CartItemWidget), findsOneWidget);
  });
}
```

---

## Best Practices

### Code Style

1. Use `const` constructors where possible
2. Extract reusable widgets
3. Keep build methods clean
4. Use meaningful variable names
5. Add documentation comments

### Performance

1. Use `const` widgets
2. Implement proper list virtualization
3. Cache network images
4. Lazy load data
5. Minimize rebuilds with `Selector`

### Error Handling

1. Always handle errors gracefully
2. Show user-friendly messages
3. Log errors for debugging
4. Implement retry mechanisms
5. Handle offline scenarios

---

For more help, contact dev@agrisupply.ug
