import 'package:flutter/material.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/onboarding/screens/vendor_onboarding_screen.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/vendor/screens/vendor_dashboard_screen.dart';
import '../../features/rider/screens/rider_dashboard_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';

class AppRouter {
  // Route Names
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String vendorOnboarding = '/vendor-onboarding';
  static const String customerHome = '/customer-home';
  static const String vendorDashboard = '/vendor-dashboard';
  static const String riderDashboard = '/rider-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  
  // Route Generator
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      
      case vendorOnboarding:
        return MaterialPageRoute(builder: (_) => const VendorOnboardingScreen());
      
      case customerHome:
        return MaterialPageRoute(builder: (_) => const CustomerHomeScreen());
      
      case vendorDashboard:
        return MaterialPageRoute(builder: (_) => const VendorDashboardScreen());
      
      case riderDashboard:
        return MaterialPageRoute(builder: (_) => const RiderDashboardScreen());
      
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
  
  // Role-based Navigation
  static String getRoleBasedRoute(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return customerHome;
      case 'vendor':
        return vendorDashboard;
      case 'rider':
        return riderDashboard;
      case 'admin':
        return adminDashboard;
      default:
        return login;
    }
  }
}
