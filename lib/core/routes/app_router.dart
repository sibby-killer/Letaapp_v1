import 'package:flutter/material.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/onboarding/screens/vendor_onboarding_screen.dart';
import '../../features/onboarding/screens/rider_onboarding_screen.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/vendor/screens/vendor_dashboard_screen.dart';
import '../../features/vendor/screens/edit_store_screen.dart';
import '../../features/rider/screens/rider_dashboard_screen.dart';
import '../../features/rider/screens/rider_settings_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_room_screen.dart';

class AppRouter {
  // Route Names
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String vendorOnboarding = '/vendor-onboarding';
  static const String riderOnboarding = '/rider-onboarding';
  static const String customerHome = '/customer-home';
  static const String vendorDashboard = '/vendor-dashboard';
  static const String editStore = '/edit-store';
  static const String riderDashboard = '/rider-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String editProfile = '/edit-profile';
  static const String riderSettings = '/rider-settings';
  static const String chatList = '/chat-list';
  static const String chatRoom = '/chat-room';
  
  // Dashboard routes (should not allow back to login)
  static const List<String> dashboardRoutes = [
    customerHome,
    vendorDashboard,
    riderDashboard,
    adminDashboard,
  ];
  
  // Route Generator
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Determine if this is a root route (dashboard)
    final isDashboard = dashboardRoutes.contains(settings.name);
    
    Widget screen;
    
    switch (settings.name) {
      case splash:
        screen = const SplashScreen();
        break;
      
      case login:
        screen = const LoginScreen();
        break;
      
      case signup:
        screen = const SignupScreen();
        break;
      
      case vendorOnboarding:
        screen = const VendorOnboardingScreen();
        break;
      
      case riderOnboarding:
        screen = const RiderOnboardingScreen();
        break;
      
      case customerHome:
        screen = const CustomerHomeScreen();
        break;
      
      case vendorDashboard:
        screen = const VendorDashboardScreen();
        break;
      
      case editStore:
        screen = const EditStoreScreen();
        break;
      
      case riderDashboard:
        screen = const RiderDashboardScreen();
        break;
      
      case adminDashboard:
        screen = const AdminDashboardScreen();
        break;
      
      case editProfile:
        screen = const EditProfileScreen();
        break;
      
      case riderSettings:
        screen = const RiderSettingsScreen();
        break;
      
      case chatList:
        screen = const ChatListScreen();
        break;
      
      case chatRoom:
        final args = settings.arguments as Map<String, dynamic>?;
        screen = ChatRoomScreen(
          roomId: args?['roomId'] as String?,
          otherUserId: args?['otherUserId'] as String?,
          otherUserName: args?['otherUserName'] as String?,
        );
        break;
      
      default:
        screen = Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        );
    }
    
    // For dashboard routes, clear back stack to prevent going back to login
    if (isDashboard) {
      return MaterialPageRoute(
        builder: (_) => PopScope(
          canPop: false,
          child: screen,
        ),
        settings: settings,
      );
    }
    
    return MaterialPageRoute(builder: (_) => screen, settings: settings);
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
  
  // Navigate to dashboard and clear stack
  static void navigateToDashboard(BuildContext context, String role) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      getRoleBasedRoute(role),
      (route) => false, // Remove all previous routes
    );
  }
  
  // Navigate to login and clear stack (for logout)
  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      login,
      (route) => false,
    );
  }
}
