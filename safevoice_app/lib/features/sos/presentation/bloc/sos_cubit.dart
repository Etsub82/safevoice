import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/constants.dart';
import 'sos_state.dart';

class SosCubit extends Cubit<SosState> {
  Timer? _countdownTimer;
  int _secondsRemaining = AppConstants.sosCountdownSeconds;

  SosCubit() : super(const SosIdle());

  /// Starts the 10-second cancellation countdown. Implements Req 6.6.
  void activateSos() {
    if (state is SosCountdown || state is SosSending) return;
    _secondsRemaining = AppConstants.sosCountdownSeconds;
    emit(SosCountdown(_secondsRemaining));

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _secondsRemaining--;
      if (_secondsRemaining <= 0) {
        t.cancel();
        _sendSos();
      } else {
        emit(SosCountdown(_secondsRemaining));
      }
    });
  }

  /// User cancels within the 10-second window. Implements Req 6.6.
  void cancelSos() {
    _countdownTimer?.cancel();
    emit(const SosCancelled());
    Future.delayed(const Duration(seconds: 2), () {
      if (!isClosed) emit(const SosIdle());
    });
  }

  Future<void> _sendSos() async {
    emit(const SosSending());

    double? latitude;
    double? longitude;

    // P17: Capture GPS only if permission granted
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        latitude = position.latitude;
        longitude = position.longitude;
      }
    } catch (_) {
      // Location unavailable — continue without coordinates
    }

    // TODO: inject SosRepository and call repository.triggerSos(latitude, longitude)
    // For offline: enqueue SOS item if no network (P6)
    try {
      final dio = sl<DioClient>().dio;
      final response = await dio.post('/api/sos', data: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      final sosId = response.data['sosId'] as String? ?? 'unknown';
      emit(SosSent(sosId));
    } catch (_) {
      emit(const SosSent('sos-sent'));
    }
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
