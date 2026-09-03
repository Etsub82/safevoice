import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/di/injection_container.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/settings/presentation/bloc/language_cubit.dart';
import '../features/offline/presentation/bloc/connectivity_cubit.dart';
import '../features/sos/presentation/bloc/sos_cubit.dart';
import '../features/emergency_contacts/presentation/bloc/emergency_contact_cubit.dart';
import '../features/notifications/services/fcm_handler.dart';
import 'router.dart';

class SafeVoiceApp extends StatefulWidget {
  const SafeVoiceApp({super.key});

  @override
  State<SafeVoiceApp> createState() => _SafeVoiceAppState();
}

class _SafeVoiceAppState extends State<SafeVoiceApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FCMHandler.instance.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Screen masking: hide sensitive content when app goes to background
    if (state == AppLifecycleState.paused) {
      // Trigger blur overlay — handled in individual screens via AppLifecycleObserver
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthCubit>()),
        BlocProvider(create: (_) => sl<LanguageCubit>()..loadSavedLanguage()),
        BlocProvider(create: (_) => sl<ConnectivityCubit>()..startMonitoring()),
        BlocProvider(create: (_) => sl<SosCubit>()),
        BlocProvider(create: (_) => sl<EmergencyContactCubit>()),
      ],
      child: BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, langState) {
          return MaterialApp.router(
            title: 'SafeVoice',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            locale: langState.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('am'), // Amharic
              Locale('om'), // Oromifa
              Locale('ti'), // Tigrinya
              Locale('so'), // Somali
            ],
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7B2D8B), // SafeVoice purple
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
