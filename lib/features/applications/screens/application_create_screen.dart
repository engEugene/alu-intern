import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../auth/providers/auth_provider.dart';

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
  bool _loading = false;

  @override
  void dispose() {
    _coverCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final opportunityDoc = await FirebaseFirestore.instance
          .collection(FirestoreConstants.opportunitiesCollection)
          .doc(widget.opportunityId)
          .get();

      final opportunityData = opportunityDoc.data();

      await FirebaseFirestore.instance
          .collection(FirestoreConstants.applicationsCollection)
          .add({
        'studentId': user.uid,
        'studentName': user.displayName,
        'studentEmail': user.email,
        'startupId': opportunityData?['startupId'],
        'startupName': opportunityData?['startupName'],
        'opportunityId': widget.opportunityId,
        'opportunityTitle': widget.opportunityTitle.isNotEmpty
            ? widget.opportunityTitle
            : opportunityData?['title'] ?? 'Opportunity',
        'coverLetter': _coverCtl.text.trim(),
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
}
