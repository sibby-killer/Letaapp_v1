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
  // PAYSTACK BANKS (Kenya)
  // ============================================================================
  
  static const List<Map<String, String>> kenyanBanks = [
    {'name': 'Kenya Commercial Bank (KCB)', 'code': 'KCB'},
    {'name': 'Equity Bank', 'code': 'EQUITY'},
    {'name': 'Co-operative Bank', 'code': 'COOP'},
    {'name': 'ABSA Bank Kenya', 'code': 'ABSA'},
    {'name': 'Standard Chartered Kenya', 'code': 'SCBK'},
    {'name': 'NCBA Bank', 'code': 'NCBA'},
    {'name': 'I&M Bank', 'code': 'IMB'},
    {'name': 'Diamond Trust Bank', 'code': 'DTB'},
    {'name': 'Stanbic Bank Kenya', 'code': 'STANBIC'},
    {'name': 'Family Bank', 'code': 'FAMILY'},
    {'name': 'Prime Bank', 'code': 'PRIME'},
    {'name': 'Bank of Africa', 'code': 'BOA'},
    {'name': 'Sidian Bank', 'code': 'SIDIAN'},
  ];

  // ============================================================================
  // MOBILE MONEY (Kenya)
  // ============================================================================
  
  static const List<Map<String, String>> mobileMoneyProviders = [
    {'name': 'M-Pesa (Safaricom)', 'code': 'MPESA'},
    {'name': 'Airtel Money', 'code': 'AIRTEL'},
    {'name': 'T-Kash (Telkom)', 'code': 'TKASH'},
  ];

  // ============================================================================
  // PAYMENT SPLIT CONFIGURATION (Kenya - KSH)
  // ============================================================================
  // Example: For a 155 KSH order:
  // - Store gets: 100 KSH (64.5%)
  // - Rider gets: 40 KSH (25.8%)
  // - Company gets: 10 KSH (6.5%)
  // - Tax/Transaction: 5 KSH (3.2%)
  
  static const double storeSharePercent = 64.5;      // Store gets ~64.5%
  static const double riderSharePercent = 25.8;      // Rider gets ~25.8%
  static const double companySharePercent = 6.5;     // Company gets ~6.5%
  static const double taxTransactionPercent = 3.2;   // Tax + transaction fees ~3.2%
  
  // Minimum order amount in KSH
  static const double minimumOrderAmount = 50.0;
  
  // Kenya phone prefix
  static const String kenyaPhonePrefix = '+254';
  static const String kenyaCountryCode = 'KE';
  
  // Default location (Kakamega, Kenya - MMUST area)
  static const double defaultLatitude = 0.2827;
  static const double defaultLongitude = 34.7519;
  static const String defaultCity = 'Kakamega';
  static const String defaultCountry = 'Kenya';
}
