import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../shared/models/opportunity_model.dart';

final class OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;

  const OpportunityCard({super.key, required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.push('/opportunities/${opportunity.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.borderCard,
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: Center(
                        child: Text(
                          opportunity.startupName.isNotEmpty
                              ? opportunity.startupName[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.titleSm.copyWith(color: AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opportunity.startupName, style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(opportunity.title, style: AppTextStyles.titleXs),
                        ],
                      ),
                    ),
                    _StatusBadge(status: opportunity.status.name),
                  ],
                ),
                if (opportunity.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    opportunity.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmLighter.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(icon: Icons.work_outline, label: opportunity.type.name.replaceAll('_', ' ')),
                    if (opportunity.location != null) ...[
                      const SizedBox(width: 8),
                      _InfoChip(icon: Icons.location_on_outlined, label: opportunity.location!),
                    ],
                    if (opportunity.remote) ...[
                      const SizedBox(width: 8),
                      _InfoChip(icon: Icons.wifi, label: 'Remote'),
                    ],
                  ],
                ),
                if (opportunity.skills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: opportunity.skills.take(4).map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentSubtle,
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(s, style: AppTextStyles.labelXs.copyWith(color: AppColors.accent)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, text) = AppColors.statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.borderSm,
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.labelXsBold.copyWith(color: text, fontSize: 10),
      ),
    );
  }
}

final class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
      ],
    );
  }
}
