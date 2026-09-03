import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/connectivity_cubit.dart';

/// Shows a banner when offline with the count of pending items.
/// Implements Req 10.3.
class OfflineStatusBanner extends StatelessWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        if (state.isOnline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          color: Colors.orange[800],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.pendingItemCount > 0
                      ? 'No connection — ${state.pendingItemCount} item(s) pending sync'
                      : 'No internet connection',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
