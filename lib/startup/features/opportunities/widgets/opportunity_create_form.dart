import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/models/opportunity_model.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';
import '../../../../student/features/onboarding/providers/onboarding_provider.dart';
import '../../../features/startups/providers/startup_providers.dart';

typedef OpportunitySavedCallback = void Function();

final class OpportunityCreateForm extends ConsumerStatefulWidget {
  final VoidCallback? onCreated;
  final Opportunity? existing;

  const OpportunityCreateForm({super.key, this.onCreated, this.existing});

  @override
  ConsumerState<OpportunityCreateForm> createState() => _OpportunityCreateFormState();
}

final class _OpportunityCreateFormState extends ConsumerState<OpportunityCreateForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _durationCtl = TextEditingController();
  final _locationCtl = TextEditingController();
  final _recruitsCtl = TextEditingController();

  OpportunityType _type = OpportunityType.internship;
  bool _remote = false;
  DateTime? _deadline;
  final _selectedSkills = <String>[];
  bool _loading = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final o = widget.existing;
    if (o != null) {
      _titleCtl.text = o.title;
      _descCtl.text = o.description;
      _durationCtl.text = o.duration ?? '';
      _locationCtl.text = o.location ?? '';
      _recruitsCtl.text = o.recruitsRequired?.toString() ?? '';
      _type = o.type;
      _remote = o.remote;
      _deadline = o.deadline;
      _selectedSkills.addAll(o.skills);
    }
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    _durationCtl.dispose();
    _locationCtl.dispose();
    _recruitsCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final startup = await ref.read(currentStartupProvider.future);
      final startupId = startup?.id ?? user.startupId ?? user.uid;

      final recruitsText = _recruitsCtl.text.trim();
      final int? recruits = recruitsText.isNotEmpty ? int.tryParse(recruitsText) : null;

      final oppMap = Opportunity(
        id: _isEditing ? widget.existing!.id : '',
        startupId: startupId,
        startupName: startup?.name ?? user.displayName ?? '',
        startupLogo: startup?.logo ?? user.photoUrl ?? '',
        title: _titleCtl.text.trim(),
        description: _descCtl.text.trim(),
        type: _type,
        duration: _durationCtl.text.trim(),
        location: _locationCtl.text.trim(),
        remote: _remote,
        skills: _selectedSkills,
        deadline: _deadline,
        recruitsRequired: recruits,
      ).toMap();
      oppMap['ownerId'] = user.uid;

      if (_isEditing) {
        oppMap.remove('createdAt');
        await FirebaseFirestore.instance
            .collection(FirestoreConstants.opportunitiesCollection)
            .doc(widget.existing!.id)
            .update(oppMap);
      } else {
        await FirebaseFirestore.instance
            .collection(FirestoreConstants.opportunitiesCollection)
            .add(oppMap);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Opportunity updated!' : 'Opportunity posted!'),
        ));
      widget.onCreated?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 30)),
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
          Text(_isEditing ? 'Edit Opportunity' : 'Create Opportunity', style: AppTextStyles.headingSm),
          const SizedBox(height: 8),
          Text(
            _isEditing ? 'Update the details of your posting' : 'Post a new internship or role for students',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
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
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _recruitsCtl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Recruits needed',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
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
                  : Text(_isEditing ? 'Save Changes' : 'Post Opportunity'),
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
