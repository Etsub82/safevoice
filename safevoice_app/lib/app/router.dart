import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/auth/presentation/screens/password_reset_screen.dart';
import '../features/cases/presentation/screens/case_list_screen.dart';
import '../features/cases/presentation/screens/case_detail_screen.dart';
import '../features/cases/presentation/screens/report_form_screen.dart';
import '../features/cases/presentation/screens/draft_list_screen.dart';
import '../features/sos/presentation/screens/sos_confirmation_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/language_selector_screen.dart';
import '../features/emergency_contacts/presentation/screens/emergency_contacts_screen.dart';
import '../features/voice/presentation/screens/transcription_review_screen.dart';
import '../features/auth/presentation/screens/demo_screen.dart';
import '../core/di/injection_container.dart';
import '../features/emergency_contacts/presentation/bloc/emergency_contact_cubit.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const passwordReset = '/password-reset';
  static const demo = '/demo';
  static const home = '/home';
  static const reportForm = '/report/new';
  static const caseList = '/cases';
  static const caseDetail = '/cases/:id';
  static const draftList = '/drafts';
  static const sos = '/sos';
  static const settings = '/settings';
  static const language = '/settings/language';
  static const emergencyContacts = '/emergency-contacts';
  static const voiceRecord = '/voice/record';
  static const transcriptionReview = '/voice/review';
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.passwordReset,
        name: 'passwordReset',
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: AppRoutes.demo,
        name: 'demo',
        builder: (context, state) => const DemoScreen(),
      ),
      GoRoute(
        path: AppRoutes.caseList,
        name: 'caseList',
        builder: (context, state) => const CaseListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'caseDetail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CaseDetailScreen(caseId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.reportForm,
        name: 'reportForm',
        builder: (context, state) => const ReportFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.draftList,
        name: 'draftList',
        builder: (context, state) => const DraftListScreen(),
      ),
      GoRoute(
        path: AppRoutes.sos,
        name: 'sos',
        builder: (context, state) => const SosConfirmationScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.language,
        name: 'language',
        builder: (context, state) => const LanguageSelectorScreen(),
      ),
      GoRoute(
        path: AppRoutes.emergencyContacts,
        name: 'emergencyContacts',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<EmergencyContactCubit>(),
          child: const EmergencyContactsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.transcriptionReview,
        name: 'transcriptionReview',
        builder: (context, state) {
          final transcript = state.extra as String? ?? '';
          return TranscriptionReviewScreen(initialTranscript: transcript);
        },
      ),
    ],
  );
}
