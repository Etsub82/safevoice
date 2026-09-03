import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

/// Demo Mode screen — only accessible when compiled with --dart-define=DEMO_MODE=true.
/// Provides one-tap login for demo/presentation accounts.
/// IMPORTANT: This screen must never appear in production builds.
class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeVoice Demo'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go(AppRoutes.caseList);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Demo login failed: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'DEMO MODE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'For presentation use only. These are test accounts.\nNot for real users.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Select a demo account:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _DemoLoginButton(
                  emoji: '👩',
                  label: 'Victim Demo',
                  subtitle: 'Report a case, track status',
                  phone: '+251911000001',
                  pin: '000001',
                  color: Colors.pink,
                ),
                const SizedBox(height: 16),
                _DemoLoginButton(
                  emoji: '👮',
                  label: 'Officer Demo',
                  subtitle: 'View & manage assigned cases',
                  phone: '+251911000002',
                  pin: '000002',
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _DemoLoginButton(
                  emoji: '👨‍💼',
                  label: 'Department Head Demo',
                  subtitle: 'Oversee cases and officers',
                  phone: '+251911000003',
                  pin: '000003',
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoLoginButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final String phone;
  final String pin;
  final Color color;

  const _DemoLoginButton({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.phone,
    required this.pin,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return SizedBox(
          height: 80,
          child: ElevatedButton(
            onPressed: state is AuthLoading
                ? null
                : () => context.read<AuthCubit>().login(
                      phoneNumber: phone,
                      password: pin,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                if (state is AuthLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
