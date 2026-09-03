import 'package:flutter/material.dart';

/// Shows locally saved report drafts. Implements Req 4.7–4.8.
class DraftListScreen extends StatelessWidget {
  const DraftListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Drafts')),
      // TODO: BlocBuilder<ReportFormCubit> for local drafts
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.drafts_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No saved drafts', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
