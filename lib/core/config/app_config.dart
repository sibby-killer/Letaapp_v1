import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // ============================================================================
  // API KEYS (ALL REQUIRED - from .env file or GitHub Secrets)
  // ============================================================================
  
  // Supabase Configuration (REQUIRED)
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Paystack Configuration (REQUIRED for payments)
  static String get paystackPublicKey => dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';
  static String get paystackSecretKey => dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';
  
  // Groq AI Configuration (REQUIRED for AI search)
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  
  // ============================================================================
  // CONFIGURATION VALIDATION
  // ============================================================================
  
  /// Check if Supabase is properly configured
  static bool get isSupabaseConfigured => 
      supabaseUrl.isNotEmpty && 
      !supabaseUrl.contains('your-project') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('your-anon-key');
  
  /// Check if Paystack is properly configured
  static bool get isPaystackConfigured =>
      paystackPublicKey.isNotEmpty &&
      !paystackPublicKey.contains('your_key') &&
      paystackSecretKey.isNotEmpty &&
      !paystackSecretKey.contains('your_key');
  
  /// Check if Groq AI is properly configured
  static bool get isGroqConfigured =>
      groqApiKey.isNotEmpty &&
      !groqApiKey.contains('your_key');
  
  /// Check if ALL required services are configured
  static bool get isFullyConfigured =>
      isSupabaseConfigured && isPaystackConfigured && isGroqConfigured;
  
  /// Get list of missing configurations
  static List<String> get missingConfigurations {
    final missing = <String>[];
    if (!isSupabaseConfigured) missing.add('Supabase (SUPABASE_URL, SUPABASE_ANON_KEY)');
    if (!isPaystackConfigured) missing.add('Paystack (PAYSTACK_PUBLIC_KEY, PAYSTACK_SECRET_KEY)');
    if (!isGroqConfigured) missing.add('Groq AI (GROQ_API_KEY)');
    return missing;
  }
  
  // ============================================================================
  // APP CONSTANTS
  // ============================================================================
  
  // Business Logic
  static const double platformFee = 5.00;        // Platform fee per order
  static const double taxRate = 0.05;            // 5% tax
  static const double companyCommissionRate = 0.10; // 10% company commission
  
  // External Services
  static const String osrmBaseUrl = 'https://router.project-osrm.org'; // Routing API
  
  // App Info
  static const String appName = 'Leta';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;
  
  // ============================================================================
  // PAYSTACK BANKS (Nigeria)
  // ============================================================================
  
  static const List<Map<String, String>> nigerianBanks = [
    {'name': 'Access Bank', 'code': '044'},
    {'name': 'Citibank Nigeria', 'code': '023'},
    {'name': 'Diamond Bank', 'code': '063'},
    {'name': 'Ecobank Nigeria', 'code': '050'},
    {'name': 'Fidelity Bank', 'code': '070'},
    {'name': 'First Bank of Nigeria', 'code': '011'},
    {'name': 'First City Monument Bank', 'code': '214'},
    {'name': 'Guaranty Trust Bank', 'code': '058'},
    {'name': 'Heritage Bank', 'code': '030'},
    {'name': 'Keystone Bank', 'code': '082'},
    {'name': 'Providus Bank', 'code': '101'},
    {'name': 'Polaris Bank', 'code': '076'},
    {'name': 'Stanbic IBTC Bank', 'code': '221'},
    {'name': 'Standard Chartered Bank', 'code': '068'},
    {'name': 'Sterling Bank', 'code': '232'},
    {'name': 'Suntrust Bank', 'code': '100'},
    {'name': 'Union Bank of Nigeria', 'code': '032'},
    {'name': 'United Bank for Africa', 'code': '033'},
    {'name': 'Unity Bank', 'code': '215'},
    {'name': 'Wema Bank', 'code': '035'},
    {'name': 'Zenith Bank', 'code': '057'},
  ];
}
