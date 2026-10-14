import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'features/auth/data/datasources/browser_auth_data_source.dart';
import 'features/auth/data/datasources/cognito_auth_data_source.dart';
import 'features/auth/data/datasources/token_store.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_access_token.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/consent/data/datasources/consent_local_data_source.dart';
import 'features/consent/data/repositories/consent_repository_impl.dart';
import 'features/consent/domain/repositories/consent_repository.dart';
import 'features/consent/domain/usecases/get_consent.dart';
import 'features/consent/domain/usecases/save_consent.dart';
import 'features/consent/presentation/bloc/consent_bloc.dart';
import 'features/models/data/datasources/model_catalog_local_data_source.dart';
import 'features/models/data/datasources/model_file_store.dart';
import 'features/models/data/datasources/model_remote_data_source.dart';
import 'features/models/data/repositories/model_catalog_repository_impl.dart';
import 'features/models/domain/repositories/model_catalog_repository.dart';
import 'features/models/domain/usecases/get_models.dart';
import 'features/models/domain/usecases/get_selected_model.dart';
import 'features/models/domain/usecases/select_model.dart';
import 'features/models/presentation/bloc/model_catalog_bloc.dart';
import 'features/scan/data/datasources/image_picker_data_source.dart';
import 'features/scan/data/datasources/onnx_classifier_data_source.dart';
import 'features/scan/data/repositories/scan_repository_impl.dart';
import 'features/scan/domain/repositories/scan_repository.dart';
import 'features/scan/domain/usecases/classify_image.dart';
import 'features/scan/domain/usecases/pick_image.dart';
import 'features/scan/presentation/bloc/scan_bloc.dart';

final sl = GetIt.instance;

/// Registers every unit of the app.
///
/// The order is external, data source, repository, use case, bloc. A bloc is a
/// factory, because each screen needs its own instance.
Future<void> initDependencies() async {
  // External
  sl.registerSingletonAsync<SharedPreferences>(SharedPreferences.getInstance);
  await sl.isReady<SharedPreferences>();
  sl.registerLazySingleton<Dio>(
    () => Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
      ),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ConsentLocalDataSource>(
    () => ConsentLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ModelCatalogLocalDataSource>(
    () => ModelCatalogLocalDataSourceImpl(preferences: sl()),
  );
  sl.registerLazySingleton<ModelRemoteDataSource>(
    () => ModelRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ModelFileStore>(ModelFileStoreImpl.new);
  sl.registerSingleton(
    const CognitoSettings(
      domain: AppConfig.cognitoDomain,
      clientId: AppConfig.cognitoClientId,
      redirectUri: AppConfig.cognitoRedirectUri,
      identityProvider: AppConfig.cognitoIdentityProvider,
    ),
  );
  sl.registerLazySingleton<CognitoAuthDataSource>(
    () => CognitoAuthDataSourceImpl(
      // The token endpoint is on the login host, not on the Edge API.
      Dio(BaseOptions(connectTimeout: const Duration(seconds: 10))),
      sl(),
    ),
  );
  sl.registerLazySingleton<BrowserAuthDataSource>(
    BrowserAuthDataSourceImpl.new,
  );
  sl.registerLazySingleton<TokenStore>(TokenStoreImpl.new);
  sl.registerLazySingleton<ImagePickerDataSource>(
    ImagePickerDataSourceImpl.new,
  );
  sl.registerLazySingleton<OnnxClassifierDataSource>(
    OnnxClassifierDataSourceImpl.new,
  );

  // Repositories
  sl.registerLazySingleton<ConsentRepository>(
    () => ConsentRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ModelCatalogRepository>(
    () => ModelCatalogRepositoryImpl(sl(), remote: sl(), files: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      cognito: sl(),
      browser: sl(),
      store: sl(),
      settings: sl(),
    ),
  );
  sl.registerLazySingleton<ScanRepository>(
    () => ScanRepositoryImpl(
      picker: sl(),
      classifier: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetConsent(sl()));
  sl.registerLazySingleton(() => SaveConsent(sl()));
  sl.registerLazySingleton(() => GetModels(sl()));
  sl.registerLazySingleton(() => GetSelectedModel(sl()));
  sl.registerLazySingleton(() => SelectModel(sl()));
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetAccessToken(sl()));
  sl.registerLazySingleton(() => PickImage(sl()));
  sl.registerLazySingleton(() => ClassifyImage(sl()));

  // Blocs
  sl.registerFactory(() => ConsentBloc(getConsent: sl(), saveConsent: sl()));
  sl.registerFactory(
    () => ModelCatalogBloc(
      getModels: sl(),
      getSelectedModel: sl(),
      selectModel: sl(),
    ),
  );
  sl.registerFactory(() => ScanBloc(pickImage: sl(), classifyImage: sl()));
}
