import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Supabase Configuration (from .env file)
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Paystack Configuration
  static String get paystackPublicKey => dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';
  static String get paystackSecretKey => dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';
  
  // Groq AI Configuration
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  
  // Check if Supabase is configured
  static bool get isSupabaseConfigured => 
      supabaseUrl.isNotEmpty && 
      supabaseUrl != 'https://your-project.supabase.co' &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'your-anon-key-here';
  
  // App Constants
  static const double platformFee = 5.00;
  static const double taxRate = 0.05; // 5%
  static const double companyCommissionRate = 0.10; // 10%
  
  // OSRM Configuration (for routing)
  static const String osrmBaseUrl = 'https://router.project-osrm.org';
  
  // App Version
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;
}
