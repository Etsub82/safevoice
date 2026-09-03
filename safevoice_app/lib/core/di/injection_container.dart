import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/register_pin_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/settings/presentation/bloc/language_cubit.dart';
import '../../features/offline/presentation/bloc/connectivity_cubit.dart';
import '../../features/emergency_contacts/data/datasources/emergency_contact_remote_datasource.dart';
import '../../features/emergency_contacts/data/repositories/emergency_contact_repository_impl.dart';
import '../../features/emergency_contacts/domain/repositories/emergency_contact_repository.dart';
import '../../features/emergency_contacts/presentation/bloc/emergency_contact_cubit.dart';
import '../../features/cases/data/case_remote_datasource.dart';
import '../../features/sos/presentation/bloc/sos_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  sl.registerLazySingleton<DioClient>(() => DioClient(sl()));

  // Auth — datasource
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<DioClient>().dio),
  );

  // Auth — repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );

  // Auth — use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => RegisterPinUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));

  // Auth — cubit
  sl.registerFactory(() => AuthCubit(
        loginUseCase: sl(),
        registerUseCase: sl(),
        registerPinUseCase: sl(),
        verifyOtpUseCase: sl(),
        authRepository: sl(),
      ));

  // Settings
  sl.registerFactory(() => LanguageCubit(sl()));

  // Connectivity
  sl.registerFactory(() => ConnectivityCubit());

  // Emergency Contacts
  sl.registerLazySingleton<EmergencyContactRemoteDataSource>(
    () => EmergencyContactRemoteDataSourceImpl(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<EmergencyContactRepository>(
    () => EmergencyContactRepositoryImpl(sl()),
  );
  sl.registerFactory(() => EmergencyContactCubit(sl()));

  // SOS
  sl.registerFactory(() => SosCubit());

  // Cases
  sl.registerLazySingleton<CaseRemoteDataSource>(
    () => CaseRemoteDataSource(sl<DioClient>().dio),
  );
}
