import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/features/billing_history/repos/billing_history_repository.dart';
import 'package:floret_collector/features/billing_history/viewmodel/billing_history_view_model.dart';
import 'package:floret_collector/features/collection_history/repos/collection_history_repository.dart';
import 'package:floret_collector/features/collection_history/viewmodel/collection_history_view_model.dart';
import 'package:floret_collector/features/home/repos/home_repository.dart';
import 'package:floret_collector/features/home/viewmodel/home_view_model.dart';
import 'package:floret_collector/features/splash/viewmodel/splash_view_model.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/auth_services.dart';
import 'package:floret_collector/services/token_storage.dart';
import 'package:floret_collector/features/direct_disposal/repos/direct_disposal_repository.dart';
import 'package:floret_collector/features/direct_disposal/viewmodel/direct_disposal_view_model.dart';
import 'package:floret_collector/features/help_support/repos/help_support_repository.dart';
import 'package:floret_collector/features/help_support/viewmodel/help_support_view_model.dart';
import 'package:floret_collector/features/issues_management/repos/issues_repository.dart';
import 'package:floret_collector/features/issues_management/viewmodel/issues_view_model.dart';
import 'package:floret_collector/features/login/repos/login_repository.dart';
import 'package:floret_collector/features/login/viewmodel/login_view_model.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // API client
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(),
  );

  //shared
  getIt.registerLazySingleton<CollectorLocalStorage>(
    () => CollectorLocalStorage(),
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
      getIt<CollectorLocalStorage>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<LoginRepository>(
    () => LoginRepositoryImpl(
      authService: getIt<AuthService>(),
      tokenStorage: getIt<TokenStorage>(),
    ),
  );

  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      getIt<ApiClient>(),
    ),
  );

  getIt.registerLazySingleton<BillingHistoryRepository>(
    () => BillingHistoryRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      collectorLocalStorage: getIt<CollectorLocalStorage>(),
    ),
  );

  getIt.registerLazySingleton<CollectionHistoryRepository>(
    () => CollectionHistoryRepository(
      apiClient: getIt<ApiClient>(),
      collectorLocalStorage: getIt<CollectorLocalStorage>(),
    ),
  );

  getIt.registerLazySingleton<IssuesRepository>(
    () => IssuesRepository(
      apiClient: getIt<ApiClient>(),
    ),
  );

  getIt.registerLazySingleton<DirectDisposalRepository>(
    () => DirectDisposalRepository(
      apiClient: getIt<ApiClient>(),
      collectorLocalStorage: getIt<CollectorLocalStorage>(),
    ),
  );

  getIt.registerLazySingleton<HelpSupportRepository>(
    () => HelpSupportRepository(
      apiClient: getIt<ApiClient>(),
    ),
  );

  // ViewModels
  getIt.registerFactory<LoginViewModel>(
    () => LoginViewModel(
      repository: getIt<LoginRepository>(),
    ),
  );

  getIt.registerFactory<HomeViewModel>(
    () => HomeViewModel(
        repository: getIt<HomeRepository>(),
        collectorLocalStorage: getIt<CollectorLocalStorage>()),
  );

  getIt.registerFactory<BillingHistoryViewModel>(
    () => BillingHistoryViewModel(
      repository: getIt<BillingHistoryRepository>(),
    ),
  );

  getIt.registerFactory<CollectionHistoryViewModel>(
    () => CollectionHistoryViewModel(
      repository: getIt<CollectionHistoryRepository>(),
    ),
  );

  getIt.registerFactory<IssuesViewModel>(
    () => IssuesViewModel(
      repository: getIt<IssuesRepository>(),
    ),
  );

  getIt.registerFactory<DirectDisposalViewModel>(
    () => DirectDisposalViewModel(
      repository: getIt<DirectDisposalRepository>(),
    ),
  );

  getIt.registerFactory<HelpSupportViewModel>(
    () => HelpSupportViewModel(
      repository: getIt<HelpSupportRepository>(),
    ),
  );

  getIt.registerFactory<SplashViewModel>(
    () => SplashViewModel(
      repository: getIt<LoginRepository>(),
    ),
  );
}
