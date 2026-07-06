import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../shared/models/opportunity_model.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../widgets/opportunity_card.dart';

final opportunityListProvider = StreamProvider<List<Opportunity>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.opportunitiesCollection)
      .where('status', isEqualTo: 'open')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
          .toList());
});

final class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final class OpportunityListScreen extends ConsumerStatefulWidget {
  const OpportunityListScreen({super.key});

  @override
  ConsumerState<OpportunityListScreen> createState() => _OpportunityListScreenState();
}

final class _OpportunityListScreenState extends ConsumerState<OpportunityListScreen> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Widget _buildBody(AsyncValue<List<Opportunity>> opportunities, String query, WidgetRef ref) {
    final data = opportunities.asData?.value;
    if (data != null) {
      final filtered = query.isEmpty
          ? data
          : data.where((o) =>
              o.title.toLowerCase().contains(query.toLowerCase()) ||
              o.startupName.toLowerCase().contains(query.toLowerCase()) ||
              o.skills.any((s) => s.toLowerCase().contains(query.toLowerCase())))
          .toList();

      if (filtered.isEmpty) {
        return EmptyState(
          icon: Icons.work_off_outlined,
          title: query.isEmpty ? 'No opportunities yet' : 'No results found',
          subtitle: query.isEmpty
              ? 'Check back later for new opportunities'
              : 'Try adjusting your search terms',
        );
      }

      return ListView.builder(
        padding: AppSpacing.screenH,
        itemCount: filtered.length,
        itemBuilder: (_, i) => OpportunityCard(opportunity: filtered[i]),
      );
    }

    if (opportunities.hasError) {
      return AppErrorWidget(
        message: 'Failed to load opportunities',
        onRetry: () => ref.invalidate(opportunityListProvider),
      );
    }

    return const LoadingShimmer();
  }

  @override
  Widget build(BuildContext context) {
    final opportunities = ref.watch(opportunityListProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Opportunities')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.screenPadding.copyWith(bottom: 12),
              child: TextField(
                controller: _searchCtl,
                onChanged: (v) => ref.read(searchQueryProvider.notifier).update(v),
                decoration: InputDecoration(
                  hintText: 'Search opportunities...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: query.isEmpty ? null : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCtl.clear();
                      ref.read(searchQueryProvider.notifier).clear();
                    },
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(opportunities, query, ref)),
          ],
        ),
      ),
    );
  }
}
