import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/sos_cubit.dart';
import '../bloc/sos_state.dart';

/// Shows 10-second countdown before SOS is dispatched.
/// User may cancel within this window. Implements Req 6.6.
class SosConfirmationScreen extends StatelessWidget {
  const SosConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[900],
      body: BlocListener<SosCubit, SosState>(
        listener: (context, state) {
          if (state is SosCancelled || state is SosIdle) {
            context.pop();
          } else if (state is SosSent) {
            // Replace — user cannot go back to countdown
            context.pushReplacement('/cases');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SOS alert sent to your emergency contacts.'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is SosPendingOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pending — No connection. SOS will be sent when you reconnect.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: BlocBuilder<SosCubit, SosState>(
              builder: (context, state) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.white, size: 80),
                    const SizedBox(height: 24),
                    const Text(
                      'SOS Alert',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state is SosCountdown) ...[
                      Text(
                        'Sending in ${state.secondsRemaining}...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: state.secondsRemaining / 10,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ],
                    if (state is SosSending)
                      const Column(children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 8),
                        Text('Sending SOS...', style: TextStyle(color: Colors.white70)),
                      ]),
                    const SizedBox(height: 32),
                    const Text(
                      'Your location and an emergency alert will be sent to your emergency contacts and SafeVoice responders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 48),
                    if (state is SosCountdown)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.read<SosCubit>().cancelSos(),
                        child: const Text('Cancel SOS', style: TextStyle(fontSize: 18)),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
