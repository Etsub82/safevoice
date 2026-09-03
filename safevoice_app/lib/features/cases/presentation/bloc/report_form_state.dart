import 'package:equatable/equatable.dart';

abstract class ReportFormState extends Equatable {
  const ReportFormState();
  @override
  List<Object?> get props => [];
}

class ReportFormInitial extends ReportFormState {
  const ReportFormInitial();
}

class ReportFormDraftSaved extends ReportFormState {
  final String draftId;
  const ReportFormDraftSaved(this.draftId);
  @override
  List<Object?> get props => [draftId];
}

class ReportFormSubmitting extends ReportFormState {
  const ReportFormSubmitting();
}

class ReportFormSubmitted extends ReportFormState {
  final String caseId;
  final bool isOfflineQueued;
  const ReportFormSubmitted(this.caseId, {this.isOfflineQueued = false});
  @override
  List<Object?> get props => [caseId, isOfflineQueued];
}

class ReportFormError extends ReportFormState {
  final String message;
  const ReportFormError(this.message);
  @override
  List<Object?> get props => [message];
}
