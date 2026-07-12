import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../../student/features/onboarding/providers/onboarding_provider.dart';
import '../../auth/providers/auth_provider.dart';

final class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final skills = ref.watch(availableSkillsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            onPressed: () => _showEditSheet(context, ref, user, skills),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.accent.withAlpha(30),
                backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                    ? Icon(Icons.person, size: 48, color: AppColors.accent)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(user?.displayName ?? 'User', style: AppTextStyles.headingSm),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              if (user?.username != null && user!.username!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('@${user.username}', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  (user?.role.name ?? 'student').toUpperCase(),
                  style: AppTextStyles.labelXsBold.copyWith(color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 24),
              if (user?.role == UserRole.startup && user?.startupId != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/startup/edit'),
                    icon: const Icon(Icons.business, size: 18),
                    label: const Text('Edit Startup Profile'),
                  ),
                ),
              const SizedBox(height: 8),
              const SizedBox(height: 32),
              if (user?.skills.isNotEmpty == true) ...[
                Align(alignment: Alignment.centerLeft, child: Text('Skills', style: AppTextStyles.titleXs)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: (user?.skills ?? []).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.borderSm,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(s, style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary)),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, AppUser? user, List<String> availableSkills) {
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _ProfileEditSheet(
        user: user,
        availableSkills: availableSkills,
      ),
    );
  }
}

final class _ProfileEditSheet extends ConsumerStatefulWidget {
  final AppUser user;
  final List<String> availableSkills;

  const _ProfileEditSheet({required this.user, required this.availableSkills});

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

final class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtl;
  late final TextEditingController _usernameCtl;
  late final TextEditingController _avatarCtl;
  late List<String> _selectedSkills;
  final _newSkillCtl = TextEditingController();
  PlatformFile? _avatarFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.user.displayName ?? '');
    _usernameCtl = TextEditingController(text: widget.user.username ?? '');
    _avatarCtl = TextEditingController(text: widget.user.photoUrl ?? '');
    _selectedSkills = List<String>.from(widget.user.skills);
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _usernameCtl.dispose();
    _avatarCtl.dispose();
    _newSkillCtl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > 3 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Image must be smaller than 3MB')));
        return;
      }

      setState(() {
        _avatarFile = file;
        _avatarCtl.text = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<String?> _uploadAvatar() async {
    final file = _avatarFile;
    if (file == null) return null;

    final bytes = file.bytes;
    final path = file.path;
    if (bytes == null && path == null) return null;

    final ext = file.extension ?? 'png';
    final fileName = 'avatar_${widget.user.uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance
        .ref()
        .child('avatars')
        .child(widget.user.uid)
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await _uploadAvatar();
      } else {
        final url = _avatarCtl.text.trim();
        avatarUrl = url.isEmpty ? null : url;
      }

      await ref.read(authProvider.notifier).updateUserInFirestore({
        'fullname': _nameCtl.text.trim(),
        'username': _usernameCtl.text.trim(),
        'avatar': avatarUrl,
        'skills': _selectedSkills,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Profile updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addNewSkill() {
    final skill = _newSkillCtl.text.trim();
    if (skill.isEmpty) return;
    if (_selectedSkills.contains(skill)) {
      _newSkillCtl.clear();
      return;
    }
    if (_selectedSkills.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 skills allowed')),
      );
      return;
    }
    setState(() {
      _selectedSkills.add(skill);
      _newSkillCtl.clear();
    });
    addSkillToFirestore(skill);
  }

  Widget _buildAvatarPicker() {
    final file = _avatarFile;
    final existingUrl = widget.user.photoUrl;

    return GestureDetector(
      onTap: _loading ? null : _pickAvatar,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.borderCard,
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.accent.withAlpha(30),
              backgroundImage: file != null && file.path != null
                  ? FileImage(File(file.path!))
                  : (existingUrl != null && existingUrl.isNotEmpty
                      ? NetworkImage(existingUrl)
                      : null),
              child: (file == null || file.path == null) &&
                      (existingUrl == null || existingUrl.isEmpty)
                  ? Icon(Icons.person, size: 28, color: AppColors.accent)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file != null ? file.name : 'Tap to upload avatar',
                    style: AppTextStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file != null ? 'Tap to change' : 'PNG/JPG, max 3MB',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(Icons.upload_file_outlined, color: AppColors.accent, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.sheetSurface,
            borderRadius: AppRadius.sheetRadius,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: AppSpacing.screenPadding.copyWith(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Edit Profile', style: AppTextStyles.headingSm),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameCtl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameCtl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Avatar', style: AppTextStyles.titleXs),
                        const SizedBox(height: 8),
                        _buildAvatarPicker(),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _avatarCtl,
                          enabled: _avatarFile == null,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Or paste avatar URL',
                            prefixIcon: Icon(Icons.link),
                            hintText: 'https://example.com/avatar.png',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 24),
                        Text('Skills (max 10)', style: AppTextStyles.titleXs),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 6,
                          children: widget.availableSkills.map((skill) {
                            final selected = _selectedSkills.contains(skill);
                            return FilterChip(
                              label: Text(skill),
                              selected: selected,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    if (_selectedSkills.length < 10) _selectedSkills.add(skill);
                                  } else {
                                    _selectedSkills.remove(skill);
                                  }
                                });
                              },
                              selectedColor: AppColors.accent.withAlpha(30),
                              checkmarkColor: AppColors.accent,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newSkillCtl,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  hintText: 'Add a new skill...',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onSubmitted: (_) => _addNewSkill(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: AppColors.accent,
                              onPressed: _addNewSkill,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _loading ? null : _save,
                            child: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
