import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'opportunity_list_screen.dart';

final class OpportunitySearchScreen extends ConsumerStatefulWidget {
  const OpportunitySearchScreen({super.key});

  @override
  ConsumerState<OpportunitySearchScreen> createState() => _OpportunitySearchScreenState();
}

final class _OpportunitySearchScreenState extends ConsumerState<OpportunitySearchScreen> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtl,
          autofocus: true,
          onChanged: (v) => ref.read(searchQueryProvider.notifier).update(v),
          decoration: const InputDecoration(
            hintText: 'Search by title, company, skills...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchCtl.clear();
                ref.read(searchQueryProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: const Center(
        child: Text('Search results will appear here'),
      ),
    );
  }
}
