import 'package:floret_collector/features/splash/viewmodel/splash_view_model.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/auth_services.dart';
import 'package:floret_collector/services/token_storage.dart';
import 'package:floret_collector/features/login/repos/login_repository.dart';
import 'package:floret_collector/features/login/viewmodel/login_view_model.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // API client
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(),
  );
  // Secure storage
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<TokenStorage>(
    () => TokenStorage(
      getIt<FlutterSecureStorage>(),
    ),
  );

  // Services
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(
      getIt<ApiClient>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<LoginRepository>(
    () => LoginRepositoryImpl(
      authService: getIt<AuthService>(),
      tokenStorage: getIt<TokenStorage>(),
    ),
  );

  // ViewModels
  getIt.registerFactory<LoginViewModel>(
    () => LoginViewModel(
      repository: getIt<LoginRepository>(),
    ),
  );

  getIt.registerFactory<SplashViewModel>(
    () => SplashViewModel(
      repository: getIt<LoginRepository>(),
    ),
  );
}
