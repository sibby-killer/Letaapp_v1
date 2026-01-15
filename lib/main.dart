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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: "assets/.env");
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Check if Supabase is configured
  if (!AppConfig.isSupabaseConfigured) {
    runApp(const ConfigurationErrorApp());
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

/// Shows an error screen if Supabase is not configured
class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF10B981),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  'Please configure your Supabase credentials in the assets/.env file:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUPABASE_URL=https://your-project.supabase.co',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'SUPABASE_ANON_KEY=your-anon-key-here',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Get your credentials from:\nsupabase.com → Your Project → Settings → API',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
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
