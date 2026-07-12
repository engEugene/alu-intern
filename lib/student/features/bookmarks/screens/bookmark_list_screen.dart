import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/opportunity_card.dart';
import '../../../../shared/providers/pagination_provider.dart';
import '../providers/bookmark_provider.dart';

final bookmarkPageLimitProvider = NotifierProvider<PageLimitNotifier, int>(PageLimitNotifier.new);

final class BookmarkListScreen extends ConsumerWidget {
  const BookmarkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkedOpportunitiesProvider);
    final limit = ref.watch(bookmarkPageLimitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: bookmarks.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => const AppErrorWidget(message: 'Failed to load bookmarks'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_outline,
              title: 'No bookmarks yet',
              subtitle: 'Save opportunities to review them later',
            );
          }

          final display = list.take(limit).toList();
          final hasMore = limit < list.length;

          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: display.length + (hasMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (hasMore && i == display.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(bookmarkPageLimitProvider.notifier).loadMore();
                      },
                      child: const Text('Load more'),
                    ),
                  ),
                );
              }
              return OpportunityCard(opportunity: display[i]);
            },
          );
        },
      ),
    );
  }
}
