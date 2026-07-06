import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../shared/models/startup_model.dart';
import '../../auth/providers/auth_provider.dart';


final class StartupCreateScreen extends ConsumerStatefulWidget {
  const StartupCreateScreen({super.key});

  @override
  ConsumerState<StartupCreateScreen> createState() => _StartupCreateScreenState();
}

final class _StartupCreateScreenState extends ConsumerState<StartupCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _websiteCtl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    _websiteCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection(FirestoreConstants.startupsCollection)
          .add(Startup(
            id: '',
            ownerId: user.uid,
            name: _nameCtl.text.trim(),
            description: _descCtl.text.trim(),
            website: _websiteCtl.text.trim(),
            members: [user.uid],
          ).toMap());

      await ref.read(authProvider.notifier).updateUserInFirestore({
        'role': 'startup',
        'startupId': doc.id,
      });

      if (context.mounted) {
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Failed to create startup: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Startup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Register Your Startup', style: AppTextStyles.headingSm),
                const SizedBox(height: 8),
                Text(
                  'Create a profile for your ALU-affiliated startup',
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
                        : const Text('Create Startup'),
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
