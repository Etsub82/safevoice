import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../app/router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/location_map_preview.dart';
import '../../../sos/presentation/widgets/sos_button.dart';
import '../../../offline/presentation/widgets/offline_status_banner.dart';
import '../../data/case_remote_datasource.dart';

/// Multi-step incident report form.
class ReportFormScreen extends StatefulWidget {
  final bool isAnonymous;
  const ReportFormScreen({super.key, this.isAnonymous = false});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Incident type ──────────────────────────────────────────────────────
  String? _selectedIncidentType;
  final _otherTypeController = TextEditingController();

  static const List<String> _incidentTypes = [
    'Physical Violence',
    'Sexual Violence',
    'Psychological Violence',
    'Economic Violence',
    'Early Marriage',
    'Other',
  ];

  // ── Description ────────────────────────────────────────────────────────
  final _descriptionController = TextEditingController();

  // ── Date ───────────────────────────────────────────────────────────────
  DateTime? _incidentDate;

  // ── Location ───────────────────────────────────────────────────────────
  final _locationController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  // ── Photos ─────────────────────────────────────────────────────────────
  final List<File> _photos = [];
  final ImagePicker _picker = ImagePicker();

  // ── Submit ─────────────────────────────────────────────────────────────
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _otherTypeController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location permission denied. Please enable in settings.')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locationController.text =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null) {
        setState(() => _photos.add(File(picked.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  // ── Submit ─────────────────────────────────────────────────────────────

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIncidentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an incident type')),
      );
      return;
    }
    if (_incidentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the incident date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final effectiveType = _selectedIncidentType == 'Other'
          ? 'Other: ${_otherTypeController.text.trim()}'
          : _selectedIncidentType!;

      final result = await sl<CaseRemoteDataSource>().submitCase(
        incidentType: effectiveType,
        description: _descriptionController.text.trim(),
        incidentDate: _incidentDate!,
        locationText: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      final caseId = (result['id'] ?? result['Id']) as String?;

      // Upload photos if any
      if (caseId != null && _photos.isNotEmpty) {
        int uploaded = 0;
        for (final photo in _photos) {
          try {
            await sl<CaseRemoteDataSource>()
                .uploadEvidence(caseId: caseId, file: photo);
            uploaded++;
          } catch (e) {
            debugPrint('Evidence upload failed: $e');
          }
        }
        if (mounted && uploaded < _photos.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '⚠️ Report submitted but ${_photos.length - uploaded} photo(s) failed to upload.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Report submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go(AppRoutes.caseList);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to submit: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAnonymous ? 'Anonymous Report' : '📝 New Report'),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Draft saved')),
            ),
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineStatusBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Anonymous banner
                    if (widget.isAnonymous)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Text(
                          'You are submitting anonymously. This may limit our ability to follow up.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),

                    // ── Incident Type ──────────────────────────────────
                    _sectionLabel('Incident Type *'),
                    DropdownButtonFormField<String>(
                      value: _selectedIncidentType,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined),
                        hintText: 'Select type...',
                      ),
                      items: _incidentTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedIncidentType = v),
                      validator: (v) =>
                          v == null ? 'Please select an incident type' : null,
                    ),

                    // "Other" free-text field
                    if (_selectedIncidentType == 'Other') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otherTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Please describe the type *',
                          prefixIcon: Icon(Icons.edit_outlined),
                        ),
                        validator: (v) => (_selectedIncidentType == 'Other' &&
                                (v == null || v.trim().isEmpty))
                            ? 'Please describe the incident type'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Description ────────────────────────────────────
                    _sectionLabel('📝 Description *'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Describe what happened...',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please describe the incident'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.voiceRecord),
                      icon: const Icon(Icons.mic),
                      label: const Text('🎙️ Record Description by Voice'),
                    ),
                    const SizedBox(height: 20),

                    // ── Photos ─────────────────────────────────────────
                    _sectionLabel('📷 Add Photos (optional)'),
                    if (_photos.isNotEmpty) ...[
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (ctx, i) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _photos[i],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(i),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: _showPhotoSourceSheet,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(_photos.isEmpty
                          ? 'Add Photo'
                          : 'Add Another Photo'),
                    ),
                    const SizedBox(height: 20),

                    // ── Date ───────────────────────────────────────────
                    _sectionLabel('📅 Incident Date *'),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(
                        _incidentDate == null
                            ? 'Tap to select date'
                            : _incidentDate!
                                .toLocal()
                                .toString()
                                .split(' ')[0],
                        style: TextStyle(
                          color: _incidentDate == null
                              ? Colors.grey
                              : null,
                        ),
                      ),
                      onTap: _pickDate,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Location ───────────────────────────────────────
                    _sectionLabel('📍 Location (optional)'),
                    OutlinedButton.icon(
                      onPressed: _isGettingLocation ? null : _getLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_isGettingLocation
                          ? 'Getting location...'
                          : _latitude != null
                              ? '📍 Location captured ✓ (tap to update)'
                              : 'Use My Current Location'),
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 8),
                      LocationMapPreview(
                        latitude: _latitude!,
                        longitude: _longitude!,
                        label: _locationController.text.isNotEmpty
                            ? _locationController.text
                            : null,
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined),
                        hintText: 'e.g. Bole, Addis Ababa',
                        helperText: 'Auto-filled from GPS or type manually',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Submit ─────────────────────────────────────────
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _isSubmitting ? 'Submitting...' : '📤 Submit Report',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const SosButton(),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      );
}
