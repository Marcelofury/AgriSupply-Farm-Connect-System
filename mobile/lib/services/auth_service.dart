import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _apiService = ApiService();

  // Get current user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final data = await _apiService.getById('users', userId);
      if (data != null) {
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? farmName,
    String? region,
    String? district,
  }) async {
    try {
      // Create auth user - the database trigger will automatically create the profile
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
          'farm_name': farmName,
          'region': region,
          'district': district,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create account');
      }

      // Wait a moment for the trigger to create the profile
      await Future.delayed(const Duration(milliseconds: 500));

      // Update additional profile fields if provided
      if (farmName != null || region != null || district != null) {
        final updateData = <String, dynamic>{};
        if (farmName != null) updateData['farm_name'] = farmName;
        if (region != null) updateData['region'] = region;
        if (district != null) updateData['district'] = district;
        
        if (updateData.isNotEmpty) {
          await _apiService.update('users', authResponse.user!.id, updateData);
        }
      }

      // Get the created profile
      return await getUserProfile(authResponse.user!.id);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Invalid credentials');
      }

      return await getUserProfile(authResponse.user!.id);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign in with phone (OTP)
  Future<bool> signInWithPhone({required String phone}) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
      );
      return true;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  // Verify OTP
  Future<UserModel?> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final authResponse = await _supabase.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );

      if (authResponse.user == null) {
        throw Exception('Invalid OTP');
      }

      // Check if user profile exists
      var user = await getUserProfile(authResponse.user!.id);

      // If no profile, create one
      if (user == null) {
        final userData = {
          'id': authResponse.user!.id,
          'phone': phone,
          'role': 'buyer',
          'is_verified': true,
          'is_premium': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final profileData = await _apiService.insert('users', userData);
        user = UserModel.fromJson(profileData);
      }

      return user;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      const webClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';
      const iosClientId = 'YOUR_GOOGLE_IOS_CLIENT_ID';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('No access token or ID token');
      }

      final authResponse = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Check if user profile exists
      var user = await getUserProfile(authResponse.user!.id);

      // If no profile, create one
      if (user == null) {
        final userData = {
          'id': authResponse.user!.id,
          'email': authResponse.user!.email,
          'full_name': googleUser.displayName ?? '',
          'photo_url': googleUser.photoUrl,
          'role': 'buyer',
          'is_verified': true,
          'is_premium': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final profileData = await _apiService.insert('users', userData);
        user = UserModel.fromJson(profileData);
      }

      return user;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }

  // Update password
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // Update user profile
  Future<UserModel?> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? photoUrl,
    String? farmName,
    String? region,
    String? district,
    String? address,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (farmName != null) updates['farm_name'] = farmName;
      if (region != null) updates['region'] = region;
      if (district != null) updates['district'] = district;
      if (address != null) updates['address'] = address;
      if (bio != null) updates['bio'] = bio;

      final data = await _apiService.update('users', userId, updates);
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto(String userId, List<int> imageBytes) async {
    try {
      final path = 'profiles/$userId/avatar.jpg';
      return await _apiService.uploadFile(
        bucket: 'avatars',
        path: path,
        fileBytes: imageBytes,
        contentType: 'image/jpeg',
      );
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Upgrade to premium
  Future<void> upgradeToPremium({required String userId}) async {
    try {
      await _apiService.update('users', userId, {
        'is_premium': true,
        'premium_since': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to upgrade to premium: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount(String userId) async {
    try {
      // Delete user data
      await _apiService.deleteRecord('users', userId);
      
      // Delete auth user (requires admin privileges or RPC call)
      await _supabase.rpc('delete_user', params: {'user_id': userId});
      
      await signOut();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final result = await _apiService.query(
        'users',
        filters: {'email': email},
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check if phone exists
  Future<bool> phoneExists(String phone) async {
    try {
      final result = await _apiService.query(
        'users',
        filters: {'phone': phone},
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
