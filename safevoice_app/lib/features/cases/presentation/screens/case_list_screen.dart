import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../offline/presentation/widgets/offline_status_banner.dart';
import '../../../sos/presentation/widgets/sos_button.dart';
import '../../domain/entities/case_entity.dart';

/// Displays all cases submitted by the authenticated user. Implements Req 8.
class CaseListScreen extends StatelessWidget {
  const CaseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Report',
            onPressed: () => context.push(AppRoutes.reportForm),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineStatusBanner(),
          // TODO: BlocBuilder<CaseListCubit> — placeholder list
          Expanded(
            child: _CasePlaceholderList(),
          ),
        ],
      ),
      floatingActionButton: const SosButton(),
    );
  }
}

class _CasePlaceholderList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder — replaced when CaseListCubit is wired
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 0,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const SizedBox.shrink(),
    );
  }
}

class CaseListTile extends StatelessWidget {
  final CaseEntity caseEntity;
  const CaseListTile({super.key, required this.caseEntity});

  Color _statusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.submitted:
        return Colors.blue;
      case CaseStatus.underReview:
        return Colors.orange;
      case CaseStatus.assigned:
        return Colors.purple;
      case CaseStatus.investigationInProgress:
        return Colors.deepPurple;
      case CaseStatus.resolved:
        return Colors.green;
      case CaseStatus.closed:
        return Colors.grey;
    }
  }

  String _statusLabel(CaseStatus status) {
    switch (status) {
      case CaseStatus.submitted:
        return 'Submitted';
      case CaseStatus.underReview:
        return 'Under Review';
      case CaseStatus.assigned:
        return 'Assigned';
      case CaseStatus.investigationInProgress:
        return 'Investigation In Progress';
      case CaseStatus.resolved:
        return 'Resolved';
      case CaseStatus.closed:
        return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(caseEntity.incidentType, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(caseEntity.id.substring(0, 8).toUpperCase()),
        trailing: Chip(
          label: Text(
            _statusLabel(caseEntity.status),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          backgroundColor: _statusColor(caseEntity.status),
          padding: EdgeInsets.zero,
        ),
        onTap: () => context.push('/cases/${caseEntity.id}'),
      ),
    );
  }
}
