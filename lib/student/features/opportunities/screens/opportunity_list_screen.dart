import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/models/opportunity_model.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/opportunity_card.dart';
import '../../../../shared/providers/pagination_provider.dart';

final opportunityPageLimitProvider = NotifierProvider<PageLimitNotifier, int>(PageLimitNotifier.new);

final opportunityListProvider = StreamProvider<List<Opportunity>>((ref) {
  final limit = ref.watch(opportunityPageLimitProvider);
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

final class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final class FilterState {
  final OpportunityType? selectedType;
  final bool remoteOnly;
  final String locationFilter;

  const FilterState({this.selectedType, this.remoteOnly = false, this.locationFilter = ''});

  FilterState copyWith({OpportunityType? type, bool? remoteOnly, String? locationFilter}) {
    return FilterState(
      selectedType: type ?? selectedType,
      remoteOnly: remoteOnly ?? this.remoteOnly,
      locationFilter: locationFilter ?? this.locationFilter,
    );
  }

  bool get isActive => selectedType != null || remoteOnly || locationFilter.isNotEmpty;
}

final class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void setType(OpportunityType? type) => state = state.copyWith(type: type);
  void toggleRemote() => state = state.copyWith(remoteOnly: !state.remoteOnly);
  void setLocation(String location) => state = state.copyWith(locationFilter: location);
  void clearAll() => state = const FilterState();
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(FilterNotifier.new);

final class OpportunityListScreen extends ConsumerStatefulWidget {
  const OpportunityListScreen({super.key});

  @override
  ConsumerState<OpportunityListScreen> createState() => _OpportunityListScreenState();
}

final class _OpportunityListScreenState extends ConsumerState<OpportunityListScreen> {
  final _searchCtl = TextEditingController();
  final _locationCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    _locationCtl.dispose();
    super.dispose();
  }

  List<Opportunity> _applyFilters(List<Opportunity> data, String query, FilterState filters) {
    var filtered = data;

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((o) =>
          o.title.toLowerCase().contains(q) ||
          o.startupName.toLowerCase().contains(q) ||
          o.skills.any((s) => s.toLowerCase().contains(q))).toList();
    }

    if (filters.selectedType != null) {
      filtered = filtered.where((o) => o.type == filters.selectedType).toList();
    }

    if (filters.remoteOnly) {
      filtered = filtered.where((o) => o.remote).toList();
    }

    if (filters.locationFilter.isNotEmpty) {
      final loc = filters.locationFilter.toLowerCase();
      filtered = filtered.where((o) =>
          (o.location ?? '').toLowerCase().contains(loc)).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final opportunities = ref.watch(opportunityListProvider);
    final query = ref.watch(searchQueryProvider);
    final filters = ref.watch(filterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Opportunities')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: AppSpacing.screenHorizontal, right: AppSpacing.screenHorizontal, top: 0),
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
            const SizedBox(height: 4),
            _buildFilterBar(filters),
            Expanded(
              child: opportunities.when(
                loading: () => const LoadingShimmer(),
                error: (e, _) => AppErrorWidget(
                  message: 'Failed to load opportunities',
                  onRetry: () => ref.invalidate(opportunityListProvider),
                ),
                data: (data) {
                  final filtered = _applyFilters(data, query, filters);

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.work_off_outlined,
                      title: query.isEmpty && !filters.isActive ? 'No opportunities yet' : 'No results found',
                      subtitle: query.isEmpty && !filters.isActive
                          ? 'Check back later for new opportunities'
                          : 'Try adjusting your search or filters',
                    );
                  }

                  final display = filtered.take(ref.read(opportunityPageLimitProvider)).toList();
                  final hasMore = ref.read(opportunityPageLimitProvider) < filtered.length;

                  return ListView.builder(
                    padding: AppSpacing.screenH,
                    itemCount: display.length + (hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (hasMore && i == display.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                ref.read(opportunityPageLimitProvider.notifier).loadMore();
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(FilterState filters) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        children: [
          if (filters.isActive)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: const Text('Clear all'),
                selected: false,
                onSelected: (_) {
                  ref.read(filterProvider.notifier).clearAll();
                  _locationCtl.clear();
                },
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  ref.read(filterProvider.notifier).clearAll();
                  _locationCtl.clear();
                },
              ),
            ),
          FilterChip(
            label: const Text('Remote'),
            selected: filters.remoteOnly,
            onSelected: (_) => ref.read(filterProvider.notifier).toggleRemote(),
            selectedColor: AppColors.accent.withAlpha(30),
            checkmarkColor: AppColors.accent,
          ),
          const SizedBox(width: 6),
          ...OpportunityType.values.map((type) {
            final selected = filters.selectedType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(type.name.replaceAll('_', ' ')),
                selected: selected,
                onSelected: (_) {
                  ref.read(filterProvider.notifier).setType(selected ? null : type);
                },
                selectedColor: AppColors.accent.withAlpha(30),
                checkmarkColor: AppColors.accent,
              ),
            );
          }),
          const SizedBox(width: 6),
          SizedBox(
            width: 150,
            height: 36,
            child: TextField(
              controller: _locationCtl,
              onChanged: (v) => ref.read(filterProvider.notifier).setLocation(v),
              style: AppTextStyles.caption,
              decoration: InputDecoration(
                hintText: 'Location...',
                hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: BorderSide(color: AppColors.divider, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
