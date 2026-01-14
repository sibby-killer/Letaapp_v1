class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  // Socket.io Configuration
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'YOUR_SOCKET_SERVER_URL',
  );
  
  // Paystack Configuration
  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'YOUR_PAYSTACK_PUBLIC_KEY',
  );
  
  static const String paystackSecretKey = String.fromEnvironment(
    'PAYSTACK_SECRET_KEY',
    defaultValue: 'YOUR_PAYSTACK_SECRET_KEY',
  );
  
  // Groq AI Configuration
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: 'YOUR_GROQ_API_KEY',
  );
  
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
