import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../app/router.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
            phoneNumber: _phoneController.text.trim(),
            password: _pinController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go(AppRoutes.caseList);
          } else if (state is AuthAccountLocked) {
            final unlockTime = state.unlocksAt.toLocal();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🔒 Account locked. Try again after '
                  '${unlockTime.hour}:${unlockTime.minute.toString().padLeft(2, '0')}',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          } else if (state is AuthError) {
            String msg = state.message;
            if (msg == 'INVALID_CREDENTIALS') {
              msg = 'The PIN is incorrect. Please try again.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Logo
                  Column(
                    children: [
                      Icon(Icons.shield, size: 72, color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        '🛡️ SAFEVOICE',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              letterSpacing: 2,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your safety, your voice',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Phone field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: '📱 Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '+251...',
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 20),

                  // PIN field
                  TextFormField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 28, letterSpacing: 12),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: '🔐 PIN',
                      counterText: '',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePin ? Icons.visibility : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscurePin = !_obscurePin),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                    ),
                    validator: Validators.pin,
                  ),

                  // Forgot PIN
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showForgotPinDialog(context),
                      child: const Text('Forgot PIN?'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Login button
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: state is AuthLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Login'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Anonymous report
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.reportForm),
                    child: const Text('📝 Report Anonymously'),
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),

                  // Demo mode button (only visible in debug/dev)
                  if (_isDemoMode()) ...[
                    const Divider(height: 40),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Demo Mode'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                      onPressed: () => context.push(AppRoutes.demo),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'DEMO — not for real users',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isDemoMode() {
    // Controlled by a compile-time flag. Set to true during demos only.
    const demoEnabled = bool.fromEnvironment('DEMO_MODE', defaultValue: false);
    return demoEnabled;
  }

  void _showForgotPinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: Colors.orange),
            SizedBox(width: 8),
            Text('Forgot PIN?'),
          ],
        ),
        content: const Text(
          'PIN recovery is not currently available.\n\n'
          'Please contact the authorized SafeVoice support process to regain access to your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
