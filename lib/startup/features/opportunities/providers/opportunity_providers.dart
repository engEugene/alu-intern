import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/models/opportunity_model.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';
import '../../startups/providers/startup_providers.dart';

final startupOpportunitiesProvider = StreamProvider<List<Opportunity>>((ref) async* {
  final startupIds = await resolveStartupIds(ref);
  if (startupIds.isEmpty) {
    yield [];
    return;
  }

  yield* FirebaseFirestore.instance
      .collection(FirestoreConstants.opportunitiesCollection)
      .where('startupId', whereIn: startupIds.toList())
      .snapshots()
      .map((snap) {
        final opportunities = snap.docs
            .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
            .toList();
        opportunities.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(0);
          final bTime = b.createdAt ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
        return opportunities;
      });
});

final startupOpportunityApplicantCountsProvider =
    StreamProvider<Map<String, int>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value({});
  return startupApplicationsStream(user.uid, startupDocId: user.startupId).map((list) {
    final counts = <String, int>{};
    for (final app in list) {
      final oppId = app['opportunityId'] as String? ?? '';
      if (oppId.isNotEmpty) counts[oppId] = (counts[oppId] ?? 0) + 1;
    }
    return counts;
  });
});