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
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to create user');
      }

      // Create user profile in database
      final userProfile = {
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'phone': phone,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('users').insert(userProfile);

      return UserModel.fromJson(userProfile);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
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
        throw Exception('Invalid credentials');
      }

      // Fetch user profile
      final userProfile = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(userProfile);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Get user profile
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch user profile: ${e.toString()}');
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
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
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
