import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

final applicationDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final doc = await FirebaseFirestore.instance
      .collection(FirestoreConstants.applicationsCollection)
      .doc(id)
      .get();
  if (!doc.exists) return null;
  return {'id': doc.id, ...doc.data()!};
});

final class ApplicationDetailScreen extends ConsumerWidget {
  final String applicationId;

  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final application = ref.watch(applicationDetailProvider(applicationId));

    return Scaffold(
      appBar: AppBar(title: const Text('Applicant')),
      body: application.when(
        loading: () => const LoadingShimmer(),
        error: (_, __) => const AppErrorWidget(message: 'Failed to load applicant'),
        data: (app) {
          if (app == null) {
            return const AppErrorWidget(message: 'Application not found');
          }

          final status = app['status'] as String? ?? 'pending';
          final (bg, text) = AppColors.statusColors(status);

          return SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(app, bg, text),
                  const SizedBox(height: 24),
                  _buildSection('Opportunity', app['opportunityTitle'] as String? ?? '-'),
                  const SizedBox(height: 16),
                  _buildSection('Email', app['studentEmail'] as String? ?? '-'),
                  const SizedBox(height: 16),
                  _buildSection('Cover Letter', app['coverLetter'] as String? ?? '-'),
                  if ((app['skills'] as List?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildSkillsSection(app['skills'] as List),
                  ],
                  if (status == 'interview' && app['interviewAt'] != null) ...[
                    const SizedBox(height: 16),
                    _buildInterviewSection(app),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: application.when(
        loading: () => null,
        error: (_, __) => null,
        data: (app) {
          if (app == null) return const SizedBox.shrink();
          final status = app['status'] as String? ?? 'pending';
          if (status == 'rejected') return const SizedBox.shrink();

          return Container(
            padding: AppSpacing.screenPadding.copyWith(top: 12, bottom: 32),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status != 'accepted') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: () => _showInterviewSheet(context, ref, applicationId),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('Schedule Interview'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: status == 'accepted' ? null : () => _updateStatus(ref, context, applicationId, 'rejected'),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: status == 'accepted' ? null : () => _updateStatus(ref, context, applicationId, 'accepted'),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> app, Color statusBg, Color statusText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.accent.withAlpha(30),
          child: Text(
            (app['studentName'] as String? ?? 'A')[0].toUpperCase(),
            style: AppTextStyles.headingSm.copyWith(color: AppColors.accent),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app['studentName'] as String? ?? 'Applicant',
                style: AppTextStyles.headingSm,
              ),
              const SizedBox(height: 4),
              Text(
                'Applied ${_formatDate((app['createdAt'] as Timestamp?)?.toDate())}',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  (app['status'] as String? ?? 'pending').toUpperCase(),
                  style: AppTextStyles.labelXsBold.copyWith(color: statusText),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleXs),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSkillsSection(List skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skills', style: AppTextStyles.titleXs),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: skills.whereType<String>().map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentSubtle,
              borderRadius: AppRadius.borderSm,
            ),
            child: Text(s, style: AppTextStyles.labelSm.copyWith(color: AppColors.accent)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildInterviewSection(Map<String, dynamic> app) {
    final date = (app['interviewAt'] as Timestamp?)?.toDate();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: AppRadius.borderCard,
        border: Border.all(color: AppColors.infoText.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available, color: AppColors.infoText, size: 18),
              const SizedBox(width: 8),
              Text('Interview Scheduled', style: AppTextStyles.titleXs.copyWith(color: AppColors.infoText)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            date != null ? DateFormat("EEEE, MMM d 'at' h:mm a").format(date) : '-',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          if (app['interviewLocation'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Location: ${app['interviewLocation']}',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (app['interviewNotes'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: ${app['interviewNotes']}',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _updateStatus(WidgetRef ref, BuildContext context, String id, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirestoreConstants.applicationsCollection)
          .doc(id)
          .update({'status': status});
      ref.invalidate(applicationDetailProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Application ${status == 'accepted' ? 'accepted' : 'rejected'}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  void _showInterviewSheet(BuildContext context, WidgetRef ref, String applicationId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InterviewScheduleSheet(
        applicationId: applicationId,
        onScheduled: () => ref.invalidate(applicationDetailProvider),
      ),
    );
  }
}

final class _InterviewScheduleSheet extends StatefulWidget {
  final String applicationId;
  final VoidCallback onScheduled;

  const _InterviewScheduleSheet({required this.applicationId, required this.onScheduled});

  @override
  State<_InterviewScheduleSheet> createState() => _InterviewScheduleSheetState();
}

final class _InterviewScheduleSheetState extends State<_InterviewScheduleSheet> {
  DateTime? _date;
  TimeOfDay? _time;
  final _locationCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _locationCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_date == null || _time == null) return;
    setState(() => _loading = true);
    try {
      final scheduled = DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        _time!.hour,
        _time!.minute,
      );

      await FirebaseFirestore.instance
          .collection(FirestoreConstants.applicationsCollection)
          .doc(widget.applicationId)
          .update({
        'status': 'interview',
        'interviewAt': Timestamp.fromDate(scheduled),
        'interviewLocation': _locationCtl.text.trim().isEmpty ? null : _locationCtl.text.trim(),
        'interviewNotes': _notesCtl.text.trim().isEmpty ? null : _notesCtl.text.trim(),
      });

      widget.onScheduled();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Failed to schedule: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule Interview', style: AppTextStyles.headingSm),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_date == null ? 'Pick date' : '${_date!.day}/${_date!.month}/${_date!.year}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(_time == null ? 'Pick time' : _time!.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationCtl,
            decoration: const InputDecoration(
              labelText: 'Location or link',
              hintText: 'e.g. Zoom link, meeting room',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesCtl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: (_date == null || _time == null || _loading) ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirm Interview'),
            ),
          ),
        ],
      ),
    );
  }
}
