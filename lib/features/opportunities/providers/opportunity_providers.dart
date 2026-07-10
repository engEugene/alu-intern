import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../shared/models/opportunity_model.dart';
import '../../auth/providers/auth_provider.dart';

final startupOpportunitiesProvider = StreamProvider<List<Opportunity>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.opportunitiesCollection)
      .where('startupId', isEqualTo: user.uid)
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
