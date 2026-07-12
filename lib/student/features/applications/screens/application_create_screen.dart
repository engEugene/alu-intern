import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';

final class ApplicationCreateScreen extends ConsumerStatefulWidget {
  final String opportunityId;
  final String opportunityTitle;

  const ApplicationCreateScreen({
    super.key,
    required this.opportunityId,
    required this.opportunityTitle,
  });

  @override
  ConsumerState<ApplicationCreateScreen> createState() => _ApplicationCreateScreenState();
}

final class _ApplicationCreateScreenState extends ConsumerState<ApplicationCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverCtl = TextEditingController();
  PlatformFile? _resumeFile;
  bool _loading = false;

  @override
  void dispose() {
    _coverCtl.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Resume must be smaller than 5MB')));
        return;
      }

      setState(() => _resumeFile = file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
    }
  }

  Future<String?> _uploadResume(String studentId) async {
    final file = _resumeFile;
    if (file == null) return null;

    final bytes = file.bytes;
    final path = file.path;
    if (bytes == null && path == null) return null;

    final ext = file.extension ?? 'pdf';
    final fileName = 'resume_${studentId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance
        .ref()
        .child('applications')
        .child(widget.opportunityId)
        .child(fileName);

    UploadTask uploadTask;
    if (bytes != null) {
      uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
    } else if (path != null) {
      final fileObj = File(path);
      uploadTask = ref.putFile(fileObj, SettableMetadata(contentType: 'application/pdf'));
    } else {
      return null;
    }

    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_resumeFile == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Please attach your resume as a PDF')));
      return;
    }

    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final opportunityDoc = await FirebaseFirestore.instance
          .collection(FirestoreConstants.opportunitiesCollection)
          .doc(widget.opportunityId)
          .get();

      final opportunityData = opportunityDoc.data();

      final resumeUrl = await _uploadResume(user.uid);

      await FirebaseFirestore.instance
          .collection(FirestoreConstants.applicationsCollection)
          .add({
        'studentId': user.uid,
        'studentName': user.displayName,
        'studentEmail': user.email,
        'startupId': opportunityData?['startupId'],
        'startupName': opportunityData?['startupName'],
        'ownerId': opportunityData?['ownerId'],
        'opportunityId': widget.opportunityId,
        'opportunityTitle': widget.opportunityTitle.isNotEmpty
            ? widget.opportunityTitle
            : opportunityData?['title'] ?? 'Opportunity',
        'coverLetter': _coverCtl.text.trim(),
        'resumeUrl': resumeUrl,
        'resumeName': _resumeFile!.name,
        'skills': user.skills,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Application submitted!')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apply to', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(widget.opportunityTitle, style: AppTextStyles.headingSm),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _coverCtl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Cover Letter',
                    hintText: 'Tell us why you\'re a great fit...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Write a cover letter' : null,
                ),
                const SizedBox(height: 24),
                Text('Resume / CV', style: AppTextStyles.titleXs),
                const SizedBox(height: 8),
                _buildResumePicker(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit Application'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumePicker() {
    final file = _resumeFile;

    return GestureDetector(
      onTap: _loading ? null : _pickResume,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.borderCard,
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: file == null
            ? Column(
                children: [
                  Icon(Icons.upload_file_outlined, color: AppColors.accent, size: 32),
                  const SizedBox(height: 8),
                  Text('Upload resume (PDF, max 5MB)', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentSubtle,
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Icon(Icons.picture_as_pdf, color: AppColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: AppTextStyles.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to change',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
