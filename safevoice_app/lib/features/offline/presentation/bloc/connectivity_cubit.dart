import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectivityState extends Equatable {
  final bool isOnline;
  final int pendingItemCount;

  const ConnectivityState({required this.isOnline, this.pendingItemCount = 0});

  ConnectivityState copyWith({bool? isOnline, int? pendingItemCount}) =>
      ConnectivityState(
        isOnline: isOnline ?? this.isOnline,
        pendingItemCount: pendingItemCount ?? this.pendingItemCount,
      );

  @override
  List<Object?> get props => [isOnline, pendingItemCount];
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription? _sub;

  ConnectivityCubit()
      : _connectivity = Connectivity(),
        super(const ConnectivityState(isOnline: true));

  Future<void> startMonitoring() async {
    final initial = await _connectivity.checkConnectivity();
    emit(state.copyWith(isOnline: _isOnline(initial)));

    _sub = _connectivity.onConnectivityChanged.listen((result) {
      emit(state.copyWith(isOnline: _isOnline(result)));
    });
  }

  void updatePendingCount(int count) {
    emit(state.copyWith(pendingItemCount: count));
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
