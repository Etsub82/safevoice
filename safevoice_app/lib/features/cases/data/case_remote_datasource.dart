import 'dart:io';
import 'package:dio/dio.dart';

class CaseRemoteDataSource {
  final Dio _dio;
  CaseRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> submitCase({
    required String incidentType,
    required String description,
    required DateTime incidentDate,
    String? locationText,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _dio.post('/api/cases', data: {
      'incidentType': incidentType,
      'description': description,
      'incidentDate': incidentDate.toIso8601String(),
      if (locationText != null) 'locationText': locationText,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadEvidence({
    required String caseId,
    required File file,
  }) async {
    // Use both / and \ to handle Windows and Android paths
    final filename = file.path.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: filename,
      ),
    });
    final res = await _dio.post(
      '/api/cases/$caseId/evidence',
      data: formData,
      options: Options(
        // Remove Content-Type header so Dio sets it with the correct multipart boundary
        contentType: 'multipart/form-data',
      ),
    );
    return res.data as Map<String, dynamic>;
  }
}
