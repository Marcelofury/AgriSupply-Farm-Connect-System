import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isFarmer => _user?.role == UserRole.farmer;
  bool get isBuyer => _user?.role == UserRole.buyer;
  bool get isAdmin => _user?.role == UserRole.admin;
  bool get isPremium => _user?.isPremium ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _setLoading(true);
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session != null) {
        await _loadUserProfile(session.user.id);
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    
    _setLoading(false);

    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadUserProfile(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      _user = await _authService.getUserProfile(userId);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to load user profile';
    }
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    String? farmName,
    String? region,
    String? district,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        farmName: farmName,
        region: region,
        district: district,
      );

      if (_user != null) {
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Failed to create account';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (_user != null) {
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Invalid credentials';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithPhone({
    required String phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.signInWithPhone(phone: phone);
      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.verifyOtp(phone: phone, otp: otp);

      if (_user != null) {
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Invalid OTP';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.signInWithGoogle();

      if (_user != null) {
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Google sign-in failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updatePassword({required String newPassword}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.updatePassword(newPassword: newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? photoUrl,
    String? farmName,
    String? region,
    String? district,
    String? address,
    String? bio,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.updateProfile(
        userId: _user!.id,
        fullName: fullName,
        phone: phone,
        photoUrl: photoUrl,
        farmName: farmName,
        region: region,
        district: district,
        address: address,
        bio: bio,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> upgradeToPremium() async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authService.upgradeToPremium(userId: _user!.id);
      _user = _user!.copyWith(isPremium: true);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _authService.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _errorMessage = _parseError(e);
    }
    
    _setLoading(false);
  }

  Future<void> refreshUser() async {
    if (_user == null) return;

    try {
      _user = await _authService.getUserProfile(_user!.id);
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _parseError(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Invalid email or password';
        case 'Email not confirmed':
          return 'Please verify your email before signing in';
        case 'User already registered':
          return 'An account with this email already exists';
        default:
          return error.message;
      }
    }
    return error.toString();
  }
}
