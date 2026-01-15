import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/services/service_locator.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/order/providers/order_provider.dart';
import 'features/vendor/providers/vendor_provider.dart';
import 'features/rider/providers/rider_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: "assets/.env");
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Check if ALL services are configured
  if (!AppConfig.isFullyConfigured) {
    runApp(ConfigurationErrorApp(missingConfigs: AppConfig.missingConfigurations));
    return;
  }
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  // Setup service locator (dependency injection)
  await setupServiceLocator();
  
  runApp(const LetaApp());
}

/// Shows an error screen if required services are not configured
class ConfigurationErrorApp extends StatelessWidget {
  final List<String> missingConfigs;
  
  const ConfigurationErrorApp({super.key, required this.missingConfigs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF10B981),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.settings_outlined,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Configuration Required',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please configure the following in GitHub Secrets or assets/.env file:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                // Missing configurations
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '❌ Missing Configurations:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...missingConfigs.map((config) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $config',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Required keys
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Required Environment Variables:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '# Supabase (supabase.com)',
                        style: TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                      Text(
                        'SUPABASE_URL=https://xxx.supabase.co',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white),
                      ),
                      Text(
                        'SUPABASE_ANON_KEY=eyJhbG...',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '# Paystack (paystack.com)',
                        style: TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                      Text(
                        'PAYSTACK_PUBLIC_KEY=pk_test_xxx',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white),
                      ),
                      Text(
                        'PAYSTACK_SECRET_KEY=sk_test_xxx',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '# Groq AI (console.groq.com)',
                        style: TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                      Text(
                        'GROQ_API_KEY=gsk_xxx',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Add these to GitHub Secrets:\nRepo Settings → Secrets → Actions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LetaApp extends StatelessWidget {
  const LetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => RiderProvider()),
      ],
      child: MaterialApp(
        title: 'Leta App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}
