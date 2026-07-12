import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/models/opportunity_model.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';

final homeOpportunitiesProvider = StreamProvider<List<Opportunity>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.opportunitiesCollection)
      .where('status', isEqualTo: 'open')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
          .toList());
});

final applicationCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.applicationsCollection)
      .where('studentId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) => snap.docs.length);
});

final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final opportunities = ref.watch(homeOpportunitiesProvider);
    final opps = opportunities.asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user),
                const SizedBox(height: 24),
                _buildSearchBar(context),
                const SizedBox(height: 30),
                _buildSectionTitle('Recommended', actionText: 'See all', onAction: () => context.go('/opportunities')),
                const SizedBox(height: 16),
                _buildRecommendedCard(context, ref, opps.isNotEmpty ? opps.first : null),
                const SizedBox(height: 30),
                _buildSectionTitle('Browse by category'),
                const SizedBox(height: 16),
                _buildCategoryList(context),
                const SizedBox(height: 30),
                _buildSectionTitle('Recent opportunities', actionText: 'See all', onAction: () => context.go('/opportunities')),
                const SizedBox(height: 16),
                opportunities.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: _ShimmerPlaceholder(),
                  ),
                  error: (_, _) => Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(
                      child: Text('Could not load opportunities', style: AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
                    ),
                  ),
                  data: (list) => _buildRecentList(context, ref, list),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader(AppUser? user) {
    final name = user?.displayName?.split(' ').first ?? 'there';
    final initials = user?.displayName != null && user!.displayName!.isNotEmpty
        ? user.displayName![0].toUpperCase()
        : '?';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $name \u{1F44B}', style: AppTextStyles.headingSm),
            const SizedBox(height: 4),
            Text(
              'Find meaningful ways to contribute.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none, size: 28, color: AppColors.textSecondary),
                  onPressed: () {},
                ),
                Positioned(
                  right: 14,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surface,
              child: Text(
                initials,
                style: AppTextStyles.titleSm.copyWith(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Search Bar ──

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/opportunities'),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Search opportunities...',
                    style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(Icons.tune, color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Section Title ──

  Widget _buildSectionTitle(String title, {String? actionText, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.titleLg),
        if (actionText != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  // ── Recommended Card ──

  Widget _buildRecommendedCard(BuildContext context, WidgetRef ref, Opportunity? opp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        gradient: AppColors.heroGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(20),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: opp != null
          ? _RecommendedContent(opportunity: opp)
          : _buildRecommendedFallback(),
    );
  }

  Widget _buildRecommendedFallback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(40),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.star_outline, color: AppColors.accent, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No featured opportunities', style: AppTextStyles.titleSm.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Check back later', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Category List ──

  Widget _buildCategoryList(BuildContext context) {
    final categories = [
      {'icon': Icons.palette_outlined, 'label': 'Design', 'color': const Color(0xFF1A2E1E)},
      {'icon': Icons.code_outlined, 'label': 'Engineering', 'color': const Color(0xFF142218)},
      {'icon': Icons.campaign_outlined, 'label': 'Marketing', 'color': const Color(0xFF1E2818)},
      {'icon': Icons.bar_chart_outlined, 'label': 'Data', 'color': const Color(0xFF18221E)},
      {'icon': Icons.more_horiz, 'label': 'Other', 'color': const Color(0xFF1A1A1A)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final color = cat['color'] as Color;
          final icon = cat['icon'] as IconData;
          final label = cat['label'] as String;
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => context.go('/opportunities'),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.textPrimary, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Recent List ──

  Widget _buildRecentList(BuildContext context, WidgetRef ref, List<Opportunity> list) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.work_off_outlined, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('No opportunities yet', style: AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: list.take(3).map((opp) => _buildRecentItem(context, opp)).toList(),
    );
  }

  Widget _buildRecentItem(BuildContext context, Opportunity opp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.push('/opportunities/${opp.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _categoryIcon(opp.category),
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opp.title, style: AppTextStyles.titleXs),
                    const SizedBox(height: 4),
                    Text(opp.startupName, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          opp.type.name.replaceAll('_', ' '),
                          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                        ),
                        if (opp.location != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on_outlined, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(opp.location!, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.bookmark_border, color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'design' => Icons.palette_outlined,
      'engineering' || 'software' || 'development' => Icons.code_outlined,
      'marketing' => Icons.campaign_outlined,
      'data' || 'analytics' => Icons.bar_chart_outlined,
      'research' => Icons.science_outlined,
      'content' || 'writing' => Icons.edit_outlined,
      'operations' => Icons.settings_outlined,
      _ => Icons.work_outline,
    };
  }
}

// ── Reusable Sub-widgets ──

final class _RecommendedContent extends StatelessWidget {
  final Opportunity opportunity;
  const _RecommendedContent({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(40),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.star_outline, color: AppColors.accent, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(opportunity.title, style: AppTextStyles.titleMd.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.business, color: AppColors.textTertiary, size: 14),
                      const SizedBox(width: 4),
                      Text(opportunity.startupName, style: AppTextStyles.bodySm.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.card.withAlpha(120),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.bookmark_border, color: AppColors.accent, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: opportunity.skills.take(3).map((s) => _buildTag(s)).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.textTertiary, size: 16),
                const SizedBox(width: 6),
                Text(
                  opportunity.duration ?? 'Flexible',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            Text(
              opportunity.createdAt != null
                  ? 'Posted ${_timeAgo(opportunity.createdAt!)}'
                  : '',
              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card.withAlpha(160),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(text, style: AppTextStyles.labelXs.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

final class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ShimmerBlock(),
        SizedBox(height: 12),
        _ShimmerBlock(),
        SizedBox(height: 12),
        _ShimmerBlock(),
      ],
    );
  }
}

final class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderCard,
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.accent.withAlpha(60),
        ),
      ),
    );
  }
}
