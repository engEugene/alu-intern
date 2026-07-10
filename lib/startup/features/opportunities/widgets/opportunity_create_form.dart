import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/models/opportunity_model.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';
import '../../../../student/features/onboarding/providers/onboarding_provider.dart';

typedef OpportunityCreatedCallback = void Function();

final class OpportunityCreateForm extends ConsumerStatefulWidget {
  final VoidCallback? onCreated;

  const OpportunityCreateForm({super.key, this.onCreated});

  @override
  ConsumerState<OpportunityCreateForm> createState() => _OpportunityCreateFormState();
}

final class _OpportunityCreateFormState extends ConsumerState<OpportunityCreateForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _durationCtl = TextEditingController();
  final _locationCtl = TextEditingController();

  OpportunityType _type = OpportunityType.internship;
  bool _remote = false;
  DateTime? _deadline;
  final _selectedSkills = <String>[];
  bool _loading = false;

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    _durationCtl.dispose();
    _locationCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection(FirestoreConstants.opportunitiesCollection)
          .add(Opportunity(
            id: '',
            startupId: user.uid,
            startupName: user.displayName ?? '',
            startupLogo: user.photoUrl ?? '',
            title: _titleCtl.text.trim(),
            description: _descCtl.text.trim(),
            type: _type,
            duration: _durationCtl.text.trim(),
            location: _locationCtl.text.trim(),
            remote: _remote,
            skills: _selectedSkills,
            deadline: _deadline,
          ).toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Opportunity posted!')));
      widget.onCreated?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to post: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skills = ref.watch(availableSkillsProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Create Opportunity', style: AppTextStyles.headingSm),
          const SizedBox(height: 8),
          Text('Post a new internship or role for students',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _titleCtl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.work_outline)),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descCtl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description_outlined),
              alignLabelWithHint: true,
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter a description' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<OpportunityType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Type',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: OpportunityType.values.map((t) => DropdownMenuItem(
              value: t,
              child: Text(t.name.replaceAll('_', ' ')),
            )).toList(),
            onChanged: (v) => setState(() => _type = v ?? OpportunityType.internship),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _durationCtl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Duration (e.g. 3 months)'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _locationCtl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Remote'),
            value: _remote,
            onChanged: (v) => setState(() => _remote = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(
              _deadline == null ? 'Deadline (optional)' : 'Deadline: ${_formatDate(_deadline!)}',
              style: AppTextStyles.body.copyWith(
                color: _deadline == null ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
            trailing: _deadline != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _deadline = null),
                  )
                : null,
            onTap: _pickDeadline,
          ),
          const SizedBox(height: 16),
          Text('Skills', style: AppTextStyles.titleXs),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: skills.map((s) {
              final selected = _selectedSkills.contains(s);
              return FilterChip(
                label: Text(s),
                selected: selected,
                onSelected: (v) => setState(() {
                  v ? _selectedSkills.add(s) : _selectedSkills.remove(s);
                }),
                selectedColor: AppColors.accent.withAlpha(30),
                checkmarkColor: AppColors.accent,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Post Opportunity'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
