import 'package:get_it/get_it.dart';
import '../database/local_database.dart';
import '../../features/auth/services/auth_service.dart';
import 'supabase_realtime_service.dart';
import '../../features/map/services/map_service.dart';
import '../../features/payment/services/payment_service.dart';
import '../../features/ai/services/ai_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Database
  getIt.registerLazySingleton<LocalDatabase>(() => LocalDatabase());
  await getIt<LocalDatabase>().initialize();
  
  // Services
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<SupabaseRealtimeService>(() => SupabaseRealtimeService());
  getIt.registerLazySingleton<MapService>(() => MapService());
  getIt.registerLazySingleton<PaymentService>(() => PaymentService());
  getIt.registerLazySingleton<AIService>(() => AIService());
}
