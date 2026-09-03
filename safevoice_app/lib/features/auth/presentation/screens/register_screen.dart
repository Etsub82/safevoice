import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/constants.dart';
import '../../../../app/router.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../../domain/usecases/register_pin_usecase.dart';

enum _RegisterStep { phoneAndDetails, createPin, confirmPin }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _displayNameController = TextEditingController();

  _RegisterStep _step = _RegisterStep.phoneAndDetails;
  String _selectedRole = 'Victim';
  String _selectedLanguage = 'en';
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    if (_step == _RegisterStep.phoneAndDetails) {
      setState(() => _step = _RegisterStep.createPin);
    } else if (_step == _RegisterStep.createPin) {
      setState(() => _step = _RegisterStep.confirmPin);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == _RegisterStep.createPin) {
      setState(() => _step = _RegisterStep.phoneAndDetails);
    } else if (_step == _RegisterStep.confirmPin) {
      setState(() => _step = _RegisterStep.createPin);
    }
  }

  void _submit() {
    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs do not match. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _step = _RegisterStep.createPin);
      _pinController.clear();
      _confirmPinController.clear();
      return;
    }
    context.read<AuthCubit>().registerWithPin(
          RegisterPinParams(
            phoneNumber: _phoneController.text.trim(),
            pin: _pinController.text,
            confirmPin: _confirmPinController.text,
            role: _selectedRole,
            preferredLanguage: _selectedLanguage,
            displayName: _displayNameController.text.trim().isEmpty
                ? null
                : _displayNameController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _RegisterStep.phoneAndDetails,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step != _RegisterStep.phoneAndDetails) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Account'),
          leading: _step != _RegisterStep.phoneAndDetails
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _back,
                )
              : null,
        ),
        body: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go(AppRoutes.caseList);
            } else if (state is AuthError) {
              String msg = state.message;
              if (msg == 'PHONE_IN_USE') {
                msg = 'This phone number is already registered. Please log in.';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg), backgroundColor: Colors.red),
              );
            }
          },
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _buildStepIndicator(),
                    const SizedBox(height: 32),
                    if (_step == _RegisterStep.phoneAndDetails) _buildPhoneStep(),
                    if (_step == _RegisterStep.createPin) _buildCreatePinStep(),
                    if (_step == _RegisterStep.confirmPin) _buildConfirmPinStep(),
                    const SizedBox(height: 32),
                    _buildContinueButton(),
                    const SizedBox(height: 16),
                    if (_step == _RegisterStep.phoneAndDetails)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?'),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      ('📱', 'Phone'),
      ('🔐', 'Create PIN'),
      ('✅', 'Confirm'),
    ];
    final current = _step.index;
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i == current;
        final done = i < current;
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: done
                    ? Colors.green
                    : active
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300],
                child: Text(
                  done ? '✓' : steps[i].$1,
                  style: TextStyle(
                    fontSize: 14,
                    color: (done || active) ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[i].$2,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.phone_android, size: 56, color: Colors.blue),
        const SizedBox(height: 12),
        Text(
          '📱 Your Phone Number',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We will use this to identify your account.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined),
            hintText: '+251...',
            contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
          validator: Validators.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _displayNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Your Name (optional)',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedRole,
          decoration: const InputDecoration(
            labelText: 'I am registering as',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'Victim', child: Text('Victim')),
            DropdownMenuItem(value: 'Guardian', child: Text('Guardian (for a child)')),
            DropdownMenuItem(value: 'Witness', child: Text('Witness')),
          ],
          onChanged: (v) => setState(() => _selectedRole = v!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedLanguage,
          decoration: const InputDecoration(
            labelText: 'Language',
            prefixIcon: Icon(Icons.language),
          ),
          items: AppConstants.supportedLanguageCodes
              .map((code) => DropdownMenuItem(
                    value: code,
                    child: Text(AppConstants.languageNames[code] ?? code),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedLanguage = v!),
        ),
      ],
    );
  }

  Widget _buildCreatePinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_outline, size: 56, color: Colors.orange),
        const SizedBox(height: 12),
        Text(
          '🔐 Create Your SafeVoice PIN',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your PIN helps protect your account.\nChoose 6 digits you will remember.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _pinController,
          obscureText: _obscurePin,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 28, letterSpacing: 12),
          decoration: InputDecoration(
            labelText: 'Enter 6-digit PIN',
            counterText: '',
            prefixIcon: const Icon(Icons.pin_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscurePin ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          ),
          validator: Validators.pin,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.security, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your PIN is encrypted and never shared.',
                  style: TextStyle(fontSize: 13, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
        const SizedBox(height: 12),
        Text(
          '🔐 Confirm Your PIN',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your PIN again to confirm.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _confirmPinController,
          obscureText: _obscureConfirm,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 28, letterSpacing: 12),
          decoration: InputDecoration(
            labelText: 'Confirm PIN',
            counterText: '',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          ),
          validator: (v) {
            final pinErr = Validators.pin(v);
            if (pinErr != null) return pinErr;
            if (v != _pinController.text) return 'PINs do not match';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: state is AuthLoading ? null : _next,
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: state is AuthLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_step == _RegisterStep.confirmPin ? 'Create Account' : 'Continue'),
          ),
        );
      },
    );
  }
}
