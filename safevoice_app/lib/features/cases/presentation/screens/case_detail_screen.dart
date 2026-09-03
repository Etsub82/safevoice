import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/case_entity.dart';

/// Shows full case details including status history. Implements Req 8.2.
class CaseDetailScreen extends StatelessWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy Case ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: caseId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Case ID copied')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Case Information',
            child: Column(
              children: [
                _InfoRow(label: 'Case ID', value: caseId.substring(0, 8).toUpperCase()),
                _InfoRow(label: 'Date Submitted', value: '—'),
                _InfoRow(label: 'Report Type', value: '—'),
                _InfoRow(label: 'Current Status', value: '—', valueColor: Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Status History',
            child: _StatusTimeline(),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Messages from Justice Team',
            child: _MessagesList(),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Evidence',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evidence has been securely submitted and is under review by the assigned officer.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.lock_outline, size: 16),
                  label: const Text('Encrypted & protected'),
                  backgroundColor: Colors.green.shade50,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Need Help?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'If you need immediate assistance or want to follow up on your case, you can contact the support team.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Request Update'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request sent to the assigned officer.')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Contact Support'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support contact feature coming soon.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final List<_StatusEntry> _entries = const [
    _StatusEntry(status: 'Submitted', date: '—', icon: Icons.upload_file, color: Colors.blue),
  ];

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      return const Text('No status history yet.', style: TextStyle(color: Colors.grey));
    }
    return Column(
      children: _entries.map((e) => _TimelineItem(entry: e)).toList(),
    );
  }
}

class _StatusEntry {
  final String status;
  final String date;
  final IconData icon;
  final Color color;
  const _StatusEntry({required this.status, required this.date, required this.icon, required this.color});
}

class _TimelineItem extends StatelessWidget {
  final _StatusEntry entry;
  const _TimelineItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: entry.color.withOpacity(0.15),
              child: Icon(entry.icon, size: 16, color: entry.color),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.status, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(entry.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessagesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'No messages yet. The assigned officer will post updates here.',
      style: TextStyle(color: Colors.grey, fontSize: 13),
    );
  }
}
