import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// User reviews and edits AI transcription before report finalization.
/// Implements P27: transcription must be seen before submit.
class TranscriptionReviewScreen extends StatefulWidget {
  final String initialTranscript;
  const TranscriptionReviewScreen({super.key, required this.initialTranscript});

  @override
  State<TranscriptionReviewScreen> createState() => _TranscriptionReviewScreenState();
}

class _TranscriptionReviewScreenState extends State<TranscriptionReviewScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTranscript);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _useTranscript() {
    // Return the (possibly edited) transcript to the report form
    context.pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Transcription')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'The audio has been transcribed. Review and edit below before adding to your report.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextFormField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  hintText: 'Transcribed text appears here...',
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _useTranscript,
              child: const Text('Use This Transcription'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.pop(null),
              child: const Text('Discard and Type Manually'),
            ),
          ],
        ),
      ),
    );
  }
}
