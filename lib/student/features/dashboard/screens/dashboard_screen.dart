import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/models/opportunity_model.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';
import '../../../../shared/providers/pagination_provider.dart';
import '../../bookmarks/providers/bookmark_provider.dart';

final dashboardOpportunitiesProvider = StreamProvider<List<Opportunity>>((ref) {
  final limit = ref.watch(homePageLimitProvider);
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.opportunitiesCollection)
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt', descending: true)
      .orderBy(FieldPath.documentId, descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
          .toList())
      .handleError((error, _) => <Opportunity>[]);
});

final studentApplicationCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.applicationsCollection)
      .where('studentId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) => snap.docs.length);
});

final studentBookmarkCountProvider = StreamProvider<int>((ref) {
  final ids = ref.watch(bookmarkIdsProvider).value ?? [];
  return Stream.value(ids.length);
});

final sortingMatchingOpportunitiesProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null || user.skills.isEmpty) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.opportunitiesCollection)
      .where('status', isEqualTo: 'open')
      .where('skills', arrayContainsAny: user.skills)
      .snapshots()
      .map((snap) => snap.docs.length);
});

final class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final appCount = ref.watch(studentApplicationCountProvider).value ?? 0;
    final bookmarkCount = ref.watch(studentBookmarkCountProvider).value ?? 0;
    final matchingOpps = ref.watch(sortingMatchingOpportunitiesProvider).value ?? 0;
    final opportunities = ref.watch(dashboardOpportunitiesProvider);
    final opps = opportunities.asData?.value ?? [];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user),
                const SizedBox(height: 24),
                _buildStatsRow(appCount, bookmarkCount, matchingOpps),
                const SizedBox(height: 24),
                _buildSearchBar(context),
                const SizedBox(height: 30),
                _buildSectionTitle('Recommended', actionText: 'See all', onAction: () => context.go('/opportunities')),
                const SizedBox(height: 16),
                _buildRecommendedCard(context, ref, opps.isNotEmpty ? opps.first : null),
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

  Widget _buildStatsRow(int apps, int bookmarks, int matching) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.description_outlined, label: 'Applications', value: apps.toString())),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.bookmark_outline, label: 'Bookmarks', value: bookmarks.toString())),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.bolt_outlined, label: 'Matches', value: matching.toString())),
      ],
    );
  }

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
            Text('Hello, $name', style: AppTextStyles.headingSm),
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
                  right: 14, top: 12,
                  child: Container(
                    width: 8, height: 8,
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
              child: Text(initials, style: AppTextStyles.titleSm.copyWith(color: AppColors.accent)),
            ),
          ],
        ),
      ],
    );
  }

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
                  Text('Search opportunities...', style: AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
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

  Widget _buildSectionTitle(String title, {String? actionText, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.titleLg),
        if (actionText != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionText, style: AppTextStyles.labelSm.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildRecommendedCard(BuildContext context, WidgetRef ref, Opportunity? opp) {
    return GestureDetector(
      onTap: opp != null ? () => context.push('/opportunities/${opp.id}') : null,
      child: Container(
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
        child: opp != null ? _RecommendedContent(opportunity: opp) : _buildRecommendedFallback(),
      ),
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

    final hasMore = list.length >= ref.read(homePageLimitProvider);

    return Column(
      children: [
        ...list.map((opp) => _buildRecentItem(context, ref, opp)),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(homePageLimitProvider.notifier).loadMore();
                },
                child: const Text('Load more'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentItem(BuildContext context, WidgetRef ref, Opportunity opp) {
    final isBookmarked = ref.watch(isBookmarkedProvider(opp.id));
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
                child: Icon(Icons.work_outline, color: AppColors.accent, size: 22),
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
                        Text(opp.type.name.replaceAll('_', ' '), style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
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
              GestureDetector(
                onTap: () => ref.read(bookmarkProvider.notifier).toggle(opp.id),
                child: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? AppColors.accent : AppColors.textTertiary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderCard,
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.titleSm.copyWith(color: AppColors.accent)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

final class _RecommendedContent extends ConsumerWidget {
  final Opportunity opportunity;
  const _RecommendedContent({required this.opportunity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(isBookmarkedProvider(opportunity.id));
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
              onTap: () => ref.read(bookmarkProvider.notifier).toggle(opportunity.id),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.card.withAlpha(120),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8, runSpacing: 6,
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
                Text(opportunity.duration ?? 'Flexible', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            Text(
              opportunity.createdAt != null ? 'Posted ${_timeAgo(opportunity.createdAt!)}' : '',
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
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent.withAlpha(60)),
      ),
    );
  }
}

final homePageLimitProvider = NotifierProvider<PageLimitNotifier, int>(PageLimitNotifier.new);
