import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _apiService = ApiService();

  // Get current user profile
  Future<UserModel?> getUserProfile(final String userId) async {
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

  // Sign up with email OTP (for mobile - sends 6-digit code instead of confirmation link)
  Future<bool> signUpWithEmailOtp({
    required final String email,
    required final String password,
    required final String fullName,
    required final String phone,
    required final String role,
    final String? farmName,
    final String? region,
    final String? district,
  }) async {
    try {
      print('[AuthService] Starting email OTP signup for: $email');
      
      // Send OTP to email - Supabase will send a 6-digit code
      await _supabase.auth.signInWithOtp(
        email: email,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
          'farm_name': farmName,
          'region': region,
          'district': district,
          'password': password, // Store temporarily in metadata for later
        },
      );

      print('[AuthService] OTP sent successfully to $email');
      return true;
    } on AuthException catch (e) {
      print('[AuthService] AuthException: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('[AuthService] General Exception: $e');
      throw Exception('Failed to send OTP: $e');
    }
  }

  // Verify email OTP and complete signup
  Future<UserModel?> verifyEmailOtp({
    required final String email,
    required final String otp,
    required final String password,
    required final String fullName,
    required final String phone,
    required final String role,
    final String? farmName,
    final String? region,
    final String? district,
  }) async {
    try {
      print('[AuthService] Verifying OTP for email: $email');
      
      // Verify the OTP
      final authResponse = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (authResponse.user == null) {
        print('[AuthService] ERROR: No user in verify response');
        throw Exception('Invalid verification code');
      }

      print('[AuthService] OTP verified successfully. User ID: ${authResponse.user!.id}');
      
      // Now update the user's password (OTP signup doesn't set password)
      try {
        await _supabase.auth.updateUser(
          UserAttributes(password: password),
        );
        print('[AuthService] Password set successfully');
      } catch (passwordError) {
        print('[AuthService] Warning: Could not set password: $passwordError');
      }

      // Check if profile already exists (from trigger)
      UserModel? profile;
      try {
        profile = await getUserProfile(authResponse.user!.id);
        print('[AuthService] Profile exists: ${profile?.id}');
      } catch (e) {
        print('[AuthService] Profile does not exist, creating...');
      }

      // If no profile exists, create it manually
      if (profile == null) {
        try {
          final profileData = await _supabase.from('users').insert({
            'id': authResponse.user!.id,
            'email': email,
            'full_name': fullName,
            'phone': phone,
            'role': role,
            'farm_name': farmName,
            'region': region,
            'district': district,
            'is_verified': true,
          }).select().single();
          
          profile = UserModel.fromJson(profileData);
          print('[AuthService] Profile created successfully');
        } catch (createError) {
          print('[AuthService] ERROR creating profile: $createError');
          throw Exception('Failed to create user profile: $createError');
        }
      }

      return profile;
    } on AuthException catch (e) {
      print('[AuthService] AuthException: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('[AuthService] General Exception: $e');
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Resend email OTP
  Future<bool> resendEmailOtp({required final String email}) async {
    try {
      print('[AuthService] Resending OTP to: $email');
      
      await _supabase.auth.signInWithOtp(
        email: email,
      );

      print('[AuthService] OTP resent successfully');
      return true;
    } on AuthException catch (e) {
      print('[AuthService] AuthException: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('[AuthService] General Exception: $e');
      throw Exception('Failed to resend OTP: $e');
    }
  }

  // Legacy sign up method (keeping for backward compatibility)
  // Use signUpWithEmailOtp for mobile apps instead
  Future<UserModel?> signUp({
    required final String email,
    required final String password,
    required final String fullName,
    required final String phone,
    required final String role,
    final String? farmName,
    final String? region,
    final String? district,
  }) async {
    try {
      print('[AuthService] Starting signup for email: $email');
      
      // Check if user already exists - if so, try to sign in instead
      try {
        final existingSession = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        if (existingSession.user != null) {
          print('[AuthService] User already exists, attempting to fetch/create profile...');
          
          // Try to get existing profile
          var profile = await getUserProfile(existingSession.user!.id);
          
          // If no profile, create one
          if (profile == null) {
            print('[AuthService] No profile found, creating one...');
            try {
              final profileData = await _supabase.from('users').insert({
                'id': existingSession.user!.id,
                'email': email,
                'full_name': fullName,
                'phone': phone,
                'role': role,
                'farm_name': farmName,
                'region': region,
                'district': district,
              }).select().single();
              
              profile = UserModel.fromJson(profileData);
              print('[AuthService] Profile created for existing user');
            } catch (profileError) {
              print('[AuthService] ERROR creating profile for existing user: $profileError');
              
              // Check if it's a duplicate phone error
              if (profileError.toString().contains('users_phone_key') || 
                  profileError.toString().contains('duplicate key')) {
                throw Exception('This phone number is already registered. Please use a different phone number.');
              }
              
              throw Exception('Failed to create profile: $profileError');
            }
          }
          
          return profile;
        }
      } catch (signInError) {
        print('[AuthService] User does not exist or wrong password, proceeding with signup...');
      }
      
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

      print('[AuthService] Auth response: ${authResponse.user?.id}');

      if (authResponse.user == null) {
        print('[AuthService] ERROR: No user in auth response');
        throw Exception('Failed to create account - No user returned');
      }

      // Wait a moment for the trigger to create the profile
      print('[AuthService] Waiting for trigger to create profile...');
      await Future.delayed(const Duration(milliseconds: 1500));

      // Try to get the profile - if it fails, the trigger didn't work
      print('[AuthService] Attempting to fetch user profile...');
      var profile = await getUserProfile(authResponse.user!.id);
      
      // If profile is null, create it manually
      if (profile == null) {
        print('[AuthService] Profile is null, attempting manual profile creation...');
        try {
          final manualProfile = await _supabase.from('users').insert({
            'id': authResponse.user!.id,
            'email': email,
            'full_name': fullName,
            'phone': phone,
            'role': role,
            'farm_name': farmName,
            'region': region,
            'district': district,
          }).select().single();
          
          profile = UserModel.fromJson(manualProfile);
          print('[AuthService] Manual profile creation successful');
        } catch (manualError) {
          print('[AuthService] ERROR in manual profile creation: $manualError');
          
          // Check if it's a duplicate phone error
          if (manualError.toString().contains('users_phone_key') || 
              manualError.toString().contains('duplicate key')) {
            throw Exception('This phone number is already registered. Please use a different phone number or sign in.');
          }
          
          throw Exception('Failed to create user profile. Error: $manualError');
        }
      } else {
        print('[AuthService] Profile fetched successfully: ${profile.id}');
      }

      // Update additional profile fields if provided
      if (farmName != null || region != null || district != null) {
        final updateData = <String, dynamic>{};
        if (farmName != null) updateData['farm_name'] = farmName;
        if (region != null) updateData['region'] = region;
        if (district != null) updateData['district'] = district;
        
        if (updateData.isNotEmpty) {
          try {
            await _apiService.update('users', authResponse.user!.id, updateData);
          } catch (updateError) {
            print('[AuthService] Warning: Failed to update profile fields: $updateError');
          }
        }
      }

      return profile;
    } on AuthException catch (e) {
      print('[AuthService] AuthException: ${e.message}');
      
      // If user already exists, show helpful message
      if (e.message.contains('already registered')) {
        throw Exception('An account with this email already exists. Please try logging in instead.');
      }
      
      throw Exception(e.message);
    } catch (e) {
      print('[AuthService] General Exception: $e');
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required final String email,
    required final String password,
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
  Future<bool> signInWithPhone({required final String phone}) async {
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
    required final String phone,
    required final String otp,
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

      final googleSignIn = GoogleSignIn(
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
  Future<void> resetPassword({required final String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }

  // Update password
  Future<void> updatePassword({required final String newPassword}) async {
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
    required final String userId,
    final String? fullName,
    final String? phone,
    final String? photoUrl,
    final String? farmName,
    final String? region,
    final String? district,
    final String? address,
    final String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (farmName != null) updates['farmName'] = farmName;
      if (region != null) updates['region'] = region;
      if (district != null) updates['district'] = district;
      if (address != null) updates['address'] = address;
      if (bio != null) updates['bio'] = bio;

      final response = await _apiService.put('/users/profile', body: updates);
      final data = response['data'] ?? response;
      return UserModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto(final String userId, final List<int> imageBytes) async {
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

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount(final String userId) async {
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
  Future<bool> emailExists(final String email) async {
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
  Future<bool> phoneExists(final String phone) async {
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
