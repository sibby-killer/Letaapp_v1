import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user ID
  String? get currentUserId => currentUser?.id;

  // Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    try {
      // Step 1: Create auth user with metadata
      // The database trigger will auto-create the profile
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          'phone': phone,
        },
      );

      if (response.user == null) {
        throw AuthException('Failed to create account. Please try again.');
      }

      // Step 2: Wait a moment for the trigger to create the profile
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Try to update the profile with additional info
      // (In case trigger didn't capture all fields)
      try {
        await _supabase.from('users').upsert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'role': role,
          'phone': phone,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (profileError) {
        // Profile might already exist from trigger, that's okay
        debugPrint('Profile update note: $profileError');
      }

      // Step 4: Return user model
      return UserModel(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        role: role,
        phone: phone,
        isActive: true,
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      throw AuthException(_getReadableAuthError(e.message));
    } on PostgrestException catch (e) {
      throw AuthException(_getReadableDbError(e.message));
    } catch (e) {
      throw AuthException('Sign up failed. Please check your connection and try again.');
    }
  }

  // Convert technical errors to user-friendly messages
  String _getReadableAuthError(String error) {
    if (error.contains('email') && error.contains('already')) {
      return 'This email is already registered. Try logging in instead.';
    }
    if (error.contains('password') && error.contains('weak')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (error.contains('invalid') && error.contains('email')) {
      return 'Please enter a valid email address.';
    }
    if (error.contains('network') || error.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    return error;
  }

  String _getReadableDbError(String error) {
    if (error.contains('row-level security') || error.contains('42501')) {
      return 'Account created! Please log in to continue.';
    }
    if (error.contains('duplicate') || error.contains('already exists')) {
      return 'This email is already registered.';
    }
    if (error.contains('network') || error.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Something went wrong. Please try again.';
  }

  // Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Invalid email or password.');
      }

      // Fetch user profile
      try {
        final userProfile = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson(userProfile);
      } catch (profileError) {
        // Profile might not exist yet, create it
        final newProfile = {
          'id': response.user!.id,
          'email': email,
          'full_name': email.split('@').first,
          'role': 'customer',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        };
        
        try {
          await _supabase.from('users').upsert(newProfile);
        } catch (_) {
          // Ignore if upsert fails
        }
        
        return UserModel.fromJson(newProfile);
      }
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login')) {
        throw AuthException('Invalid email or password. Please try again.');
      }
      if (e.message.contains('Email not confirmed')) {
        throw AuthException('Please check your email and confirm your account first.');
      }
      throw AuthException(_getReadableAuthError(e.message));
    } catch (e) {
      throw AuthException('Login failed. Please check your connection and try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed. Please try again.');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<UserModel?> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;

      await _supabase.from('users').update(updates).eq('id', userId);

      return await getUserProfile(userId);
    } catch (e) {
      throw AuthException('Failed to update profile. Please try again.');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      if (e.message.contains('not found')) {
        throw AuthException('No account found with this email.');
      }
      throw AuthException('Could not send reset email. Please try again.');
    } catch (e) {
      throw AuthException('Password reset failed. Please check your connection.');
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}

// Custom exception for better error handling
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}

// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[AuthService] $message');
}
