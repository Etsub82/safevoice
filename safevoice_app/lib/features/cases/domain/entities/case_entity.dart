import 'package:equatable/equatable.dart';

enum CaseStatus {
  submitted,
  underReview,
  assigned,
  investigationInProgress,
  resolved,
  closed,
}

enum RiskLevel { low, medium, high }

class CaseStatusChange extends Equatable {
  final String oldStatus;
  final String newStatus;
  final DateTime changedAt;

  const CaseStatusChange({
    required this.oldStatus,
    required this.newStatus,
    required this.changedAt,
  });

  @override
  List<Object?> get props => [oldStatus, newStatus, changedAt];
}

class CaseEntity extends Equatable {
  final String id;
  final String incidentType;
  final String description;
  final DateTime incidentDate;
  final String? locationText;
  final double? latitude;
  final double? longitude;
  final CaseStatus status;
  final String? district;
  final RiskLevel? riskLevel;
  final bool isAnonymous;
  final DateTime submittedAt;
  final List<CaseStatusChange> statusHistory;

  const CaseEntity({
    required this.id,
    required this.incidentType,
    required this.description,
    required this.incidentDate,
    this.locationText,
    this.latitude,
    this.longitude,
    required this.status,
    this.district,
    this.riskLevel,
    required this.isAnonymous,
    required this.submittedAt,
    this.statusHistory = const [],
  });

  @override
  List<Object?> get props => [id, status, submittedAt];
}
