import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/models/startup_model.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';

final class StartupCreateScreen extends ConsumerStatefulWidget {
  final Startup? existingStartup;

  const StartupCreateScreen({super.key, this.existingStartup});

  @override
  ConsumerState<StartupCreateScreen> createState() => _StartupCreateScreenState();
}

final class _StartupCreateScreenState extends ConsumerState<StartupCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _websiteCtl = TextEditingController();
  final _logoCtl = TextEditingController();
  PlatformFile? _logoFile;
  bool _loading = false;

  bool get isEditing => widget.existingStartup != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existingStartup;
    if (s != null) {
      _nameCtl.text = s.name;
      _descCtl.text = s.description ?? '';
      _websiteCtl.text = s.website ?? '';
      _logoCtl.text = s.logo ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    _websiteCtl.dispose();
    _logoCtl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > 3 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Logo must be smaller than 3MB')));
        return;
      }

      setState(() {
        _logoFile = file;
        _logoCtl.text = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
    }
  }

  Future<String?> _uploadLogo(String startupId) async {
    final file = _logoFile;
    if (file == null) {
      final url = _logoCtl.text.trim();

    if (url.isNotEmpty && !url.startsWith('http')) return null;
    return url.isEmpty ? null : url;
    }

    final bytes = file.bytes;
    final path = file.path;
    if (bytes == null && path == null) return null;

    final ext = file.extension ?? 'png';
    final fileName = 'logo_${startupId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance
        .ref()
        .child('startups')
        .child(startupId)
        .child(fileName);

    UploadTask uploadTask;
    if (bytes != null) {
      uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
    } else if (path != null) {
      final fileObj = File(path);
      uploadTask = ref.putFile(fileObj, SettableMetadata(contentType: 'image/$ext'));
    } else {
      return null;
    }

    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      if (isEditing) {
        final s = widget.existingStartup!;
        final logoUrl = _logoFile != null ? await _uploadLogo(s.id) : _logoCtl.text.trim();

        await FirebaseFirestore.instance
            .collection(FirestoreConstants.startupsCollection)
            .doc(s.id)
            .update({
          'name': _nameCtl.text.trim(),
          'description': _descCtl.text.trim(),
          'website': _websiteCtl.text.trim(),
          'logo': (logoUrl == null || logoUrl.isEmpty) ? null : logoUrl,
        });

        await ref.read(authProvider.notifier).updateUserInFirestore({
          'fullname': _nameCtl.text.trim(),
          'avatar': (logoUrl == null || logoUrl.isEmpty) ? null : logoUrl,
        });
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection(FirestoreConstants.startupsCollection)
            .add(Startup(
              id: '',
              ownerId: user.uid,
              name: _nameCtl.text.trim(),
              description: _descCtl.text.trim(),
              website: _websiteCtl.text.trim(),
              members: [user.uid],
            ).toMap());

        final logoUrl = await _uploadLogo(docRef.id);

        if (logoUrl != null && logoUrl.isNotEmpty) {
          await docRef.update({'logo': logoUrl});
        }

        await ref.read(authProvider.notifier).updateUserInFirestore({
          'role': 'startup',
          'startupId': docRef.id,
          'fullname': _nameCtl.text.trim(),
          'avatar': logoUrl,
          'onboardingComplete': true,
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(isEditing ? 'Startup updated!' : 'Startup created!'),
          ));
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Startup' : 'Create Startup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEditing ? 'Edit Your Startup' : 'Register Your Startup', style: AppTextStyles.headingSm),
                const SizedBox(height: 8),
                Text(
                  isEditing
                      ? 'Update your startup profile'
                      : 'Create a profile for your ALU-affiliated startup',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameCtl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Startup Name',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter startup name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtl,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a description' : null,
                ),
                const SizedBox(height: 24),
                Text('Logo', style: AppTextStyles.titleXs),
                const SizedBox(height: 8),
                _buildLogoPicker(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _websiteCtl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Website (optional)',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(isEditing ? 'Save Changes' : 'Create Startup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPicker() {
    final file = _logoFile;
    final url = _logoCtl.text.trim();

    return Column(
      children: [
        GestureDetector(
          onTap: _loading ? null : _pickLogo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderCard,
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: file != null
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentSubtle,
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Icon(Icons.image, color: AppColors.accent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(file.name, style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('Tap to change', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(Icons.upload_file_outlined, color: AppColors.accent, size: 32),
                      const SizedBox(height: 8),
                      Text('Upload logo (PNG/JPG, max 3MB)', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
          ),
        ),
        if (url.isNotEmpty && file == null) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _logoCtl,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Logo URL',
              prefixIcon: Icon(Icons.link),
              hintText: 'https://example.com/logo.png',
            ),
          ),
        ],
      ],
    );
  }
}
