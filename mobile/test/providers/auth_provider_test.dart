/// Unit Tests for Auth Provider
/// Tests for authentication state management
library;

import 'package:flutter_test/flutter_test.dart';

// Mock User model for testing
class User {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String role;
  final String? avatar;
  final String? region;
  final String? district;
  final bool isVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.avatar,
    this.region,
    this.district,
    this.isVerified = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  User copyWith({
    String? fullName,
    String? phone,
    String? avatar,
    String? region,
    String? district,
    bool? isVerified,
  }) {
    return User(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role,
      avatar: avatar ?? this.avatar,
      region: region ?? this.region,
      district: district ?? this.district,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
    );
  }
}

// Auth state enum
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

// Mock AuthProvider for testing
class AuthProvider {
  AuthState _state = AuthState.initial;
  User? _user;
  String? _error;
  String? _accessToken;
  String? _refreshToken;

  AuthState get state => _state;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  bool get isBuyer => _user?.role == 'buyer';
  bool get isFarmer => _user?.role == 'farmer';
  bool get isAdmin => _user?.role == 'admin';
  bool get isVerified => _user?.isVerified ?? false;

  // Simulate login
  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _error = null;

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Validation
    if (email.isEmpty || password.isEmpty) {
      _state = AuthState.error;
      _error = 'Email and password are required';
      return false;
    }

    if (!_isValidEmail(email)) {
      _state = AuthState.error;
      _error = 'Invalid email format';
      return false;
    }

    if (password.length < 8) {
      _state = AuthState.error;
      _error = 'Password must be at least 8 characters';
      return false;
    }

    // Simulate successful login
    if (email == 'test@example.com' && password == 'password123') {
      _user = User(
        id: 'test-user-id',
        email: email,
        fullName: 'Test User',
        phone: '+256771234567',
        role: 'buyer',
        isVerified: true,
      );
      _accessToken = 'mock-access-token';
      _refreshToken = 'mock-refresh-token';
      _state = AuthState.authenticated;
      return true;
    }

    // Simulate farmer login
    if (email == 'farmer@example.com' && password == 'password123') {
      _user = User(
        id: 'test-farmer-id',
        email: email,
        fullName: 'Test Farmer',
        phone: '+256771234568',
        role: 'farmer',
        isVerified: true,
      );
      _accessToken = 'mock-farmer-token';
      _refreshToken = 'mock-farmer-refresh';
      _state = AuthState.authenticated;
      return true;
    }

    // Simulate admin login
    if (email == 'admin@example.com' && password == 'password123') {
      _user = User(
        id: 'test-admin-id',
        email: email,
        fullName: 'Test Admin',
        phone: '+256771234569',
        role: 'admin',
        isVerified: true,
      );
      _accessToken = 'mock-admin-token';
      _refreshToken = 'mock-admin-refresh';
      _state = AuthState.authenticated;
      return true;
    }

    _state = AuthState.error;
    _error = 'Invalid email or password';
    return false;
  }

  // Simulate registration
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? region,
    String? district,
  }) async {
    _state = AuthState.loading;
    _error = null;

    await Future.delayed(const Duration(milliseconds: 100));

    // Validation
    if (email.isEmpty ||
        password.isEmpty ||
        fullName.isEmpty ||
        phone.isEmpty) {
      _state = AuthState.error;
      _error = 'All required fields must be filled';
      return false;
    }

    if (!_isValidEmail(email)) {
      _state = AuthState.error;
      _error = 'Invalid email format';
      return false;
    }

    if (!_isValidPassword(password)) {
      _state = AuthState.error;
      _error =
          'Password must be at least 8 characters with uppercase, lowercase, and number';
      return false;
    }

    if (!_isValidUgandanPhone(phone)) {
      _state = AuthState.error;
      _error = 'Invalid Ugandan phone number';
      return false;
    }

    if (!['buyer', 'farmer'].contains(role)) {
      _state = AuthState.error;
      _error = 'Invalid role';
      return false;
    }

    // Simulate duplicate email
    if (email == 'existing@example.com') {
      _state = AuthState.error;
      _error = 'Email already registered';
      return false;
    }

    // Success
    _user = User(
      id: 'new-user-id',
      email: email,
      fullName: fullName,
      phone: phone,
      role: role,
      region: region,
      district: district,
      isVerified: false,
    );
    _accessToken = 'mock-new-token';
    _refreshToken = 'mock-new-refresh';
    _state = AuthState.authenticated;
    return true;
  }

  // Logout
  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _state = AuthState.unauthenticated;
    _error = null;
  }

  // Update profile
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? region,
    String? district,
  }) async {
    if (_user == null) {
      _error = 'Not authenticated';
      return false;
    }

    _state = AuthState.loading;

    await Future.delayed(const Duration(milliseconds: 100));

    if (phone != null && !_isValidUgandanPhone(phone)) {
      _state = AuthState.authenticated;
      _error = 'Invalid phone number';
      return false;
    }

    _user = _user!.copyWith(
      fullName: fullName,
      phone: phone,
      region: region,
      district: district,
    );
    _state = AuthState.authenticated;
    _error = null;
    return true;
  }

  // Verify phone
  Future<bool> verifyPhone(String otp) async {
    if (_user == null) {
      _error = 'Not authenticated';
      return false;
    }

    if (otp.length != 6 || !RegExp(r'^\d+$').hasMatch(otp)) {
      _error = 'Invalid OTP format';
      return false;
    }

    // Simulate valid OTP
    if (otp == '123456') {
      _user = _user!.copyWith(isVerified: true);
      return true;
    }

    _error = 'Invalid OTP';
    return false;
  }

  // Password reset
  Future<bool> forgotPassword(String email) async {
    if (!_isValidEmail(email)) {
      _error = 'Invalid email format';
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  // Refresh token
  Future<bool> refreshToken() async {
    if (_refreshToken == null) {
      _state = AuthState.unauthenticated;
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    _accessToken = 'new-access-token';
    return true;
  }

  // Check auth state
  Future<void> checkAuthState() async {
    _state = AuthState.loading;
    await Future.delayed(const Duration(milliseconds: 100));

    if (_accessToken != null && _user != null) {
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
  }

  // Helpers
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  bool _isValidUgandanPhone(String phone) {
    return RegExp(r'^\+256[0-9]{9}$').hasMatch(phone);
  }
}

void main() {
  group('AuthProvider', () {
    late AuthProvider auth;

    setUp(() {
      auth = AuthProvider();
    });

    group('Initial State', () {
      test('starts in initial state', () {
        expect(auth.state, AuthState.initial);
        expect(auth.user, isNull);
        expect(auth.error, isNull);
        expect(auth.isAuthenticated, isFalse);
      });
    });

    group('Login', () {
      test('successful login with valid credentials', () async {
        final result = await auth.login('test@example.com', 'password123');

        expect(result, isTrue);
        expect(auth.isAuthenticated, isTrue);
        expect(auth.user, isNotNull);
        expect(auth.user!.email, 'test@example.com');
        expect(auth.error, isNull);
      });

      test('login as farmer', () async {
        final result = await auth.login('farmer@example.com', 'password123');

        expect(result, isTrue);
        expect(auth.isFarmer, isTrue);
        expect(auth.isBuyer, isFalse);
      });

      test('login as admin', () async {
        final result = await auth.login('admin@example.com', 'password123');

        expect(result, isTrue);
        expect(auth.isAdmin, isTrue);
      });

      test('fails with empty email', () async {
        final result = await auth.login('', 'password123');

        expect(result, isFalse);
        expect(auth.state, AuthState.error);
        expect(auth.error, isNotNull);
      });

      test('fails with empty password', () async {
        final result = await auth.login('test@example.com', '');

        expect(result, isFalse);
        expect(auth.error, isNotNull);
      });

      test('fails with invalid email format', () async {
        final result = await auth.login('invalid-email', 'password123');

        expect(result, isFalse);
        expect(auth.error, contains('email'));
      });

      test('fails with short password', () async {
        final result = await auth.login('test@example.com', 'short');

        expect(result, isFalse);
        expect(auth.error, contains('8 characters'));
      });

      test('fails with wrong credentials', () async {
        final result = await auth.login('test@example.com', 'wrongpassword');

        expect(result, isFalse);
        expect(auth.error, contains('Invalid'));
      });
    });

    group('Registration', () {
      test('successful registration', () async {
        final result = await auth.register(
          email: 'new@example.com',
          password: 'SecurePass123',
          fullName: 'New User',
          phone: '+256771234567',
          role: 'buyer',
        );

        expect(result, isTrue);
        expect(auth.isAuthenticated, isTrue);
        expect(auth.user!.email, 'new@example.com');
        expect(auth.isVerified, isFalse);
      });

      test('registration as farmer', () async {
        final result = await auth.register(
          email: 'newfarmer@example.com',
          password: 'SecurePass123',
          fullName: 'New Farmer',
          phone: '+256771234567',
          role: 'farmer',
          region: 'Central',
          district: 'Kampala',
        );

        expect(result, isTrue);
        expect(auth.isFarmer, isTrue);
      });

      test('fails with existing email', () async {
        final result = await auth.register(
          email: 'existing@example.com',
          password: 'SecurePass123',
          fullName: 'Test',
          phone: '+256771234567',
          role: 'buyer',
        );

        expect(result, isFalse);
        expect(auth.error, contains('already registered'));
      });

      test('fails with weak password', () async {
        final result = await auth.register(
          email: 'new@example.com',
          password: 'weak',
          fullName: 'Test',
          phone: '+256771234567',
          role: 'buyer',
        );

        expect(result, isFalse);
        expect(auth.error, contains('Password'));
      });

      test('fails with invalid phone', () async {
        final result = await auth.register(
          email: 'new@example.com',
          password: 'SecurePass123',
          fullName: 'Test',
          phone: '1234567890',
          role: 'buyer',
        );

        expect(result, isFalse);
        expect(auth.error, contains('phone'));
      });

      test('fails with invalid role', () async {
        final result = await auth.register(
          email: 'new@example.com',
          password: 'SecurePass123',
          fullName: 'Test',
          phone: '+256771234567',
          role: 'superuser',
        );

        expect(result, isFalse);
        expect(auth.error, contains('role'));
      });
    });

    group('Logout', () {
      test('clears user data on logout', () async {
        await auth.login('test@example.com', 'password123');
        expect(auth.isAuthenticated, isTrue);

        await auth.logout();

        expect(auth.isAuthenticated, isFalse);
        expect(auth.user, isNull);
        expect(auth.state, AuthState.unauthenticated);
      });
    });

    group('Profile Update', () {
      setUp(() async {
        await auth.login('test@example.com', 'password123');
      });

      test('updates profile successfully', () async {
        final result = await auth.updateProfile(
          fullName: 'Updated Name',
          region: 'Western',
        );

        expect(result, isTrue);
        expect(auth.user!.fullName, 'Updated Name');
        expect(auth.user!.region, 'Western');
      });

      test('fails with invalid phone', () async {
        final result = await auth.updateProfile(
          phone: 'invalid',
        );

        expect(result, isFalse);
        expect(auth.error, contains('phone'));
      });
    });

    group('Phone Verification', () {
      setUp(() async {
        await auth.register(
          email: 'verify@example.com',
          password: 'SecurePass123',
          fullName: 'Test',
          phone: '+256771234567',
          role: 'buyer',
        );
      });

      test('verifies phone with correct OTP', () async {
        final result = await auth.verifyPhone('123456');

        expect(result, isTrue);
        expect(auth.isVerified, isTrue);
      });

      test('fails with incorrect OTP', () async {
        final result = await auth.verifyPhone('000000');

        expect(result, isFalse);
        expect(auth.error, contains('Invalid OTP'));
      });

      test('fails with invalid OTP format', () async {
        final result = await auth.verifyPhone('123');

        expect(result, isFalse);
        expect(auth.error, contains('format'));
      });
    });

    group('Password Reset', () {
      test('sends reset email for valid email', () async {
        final result = await auth.forgotPassword('test@example.com');
        expect(result, isTrue);
      });

      test('fails for invalid email', () async {
        final result = await auth.forgotPassword('invalid');
        expect(result, isFalse);
      });
    });

    group('Token Refresh', () {
      test('refreshes token when authenticated', () async {
        await auth.login('test@example.com', 'password123');
        final result = await auth.refreshToken();

        expect(result, isTrue);
      });

      test('fails when not authenticated', () async {
        final result = await auth.refreshToken();

        expect(result, isFalse);
        expect(auth.state, AuthState.unauthenticated);
      });
    });

    group('Role Checks', () {
      test('isBuyer returns true for buyer role', () async {
        await auth.login('test@example.com', 'password123');
        expect(auth.isBuyer, isTrue);
        expect(auth.isFarmer, isFalse);
        expect(auth.isAdmin, isFalse);
      });

      test('isFarmer returns true for farmer role', () async {
        await auth.login('farmer@example.com', 'password123');
        expect(auth.isFarmer, isTrue);
        expect(auth.isBuyer, isFalse);
        expect(auth.isAdmin, isFalse);
      });

      test('isAdmin returns true for admin role', () async {
        await auth.login('admin@example.com', 'password123');
        expect(auth.isAdmin, isTrue);
        expect(auth.isBuyer, isFalse);
        expect(auth.isFarmer, isFalse);
      });
    });
  });
}
