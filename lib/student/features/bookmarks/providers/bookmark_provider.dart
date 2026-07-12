import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';
import '../../../../shared/models/opportunity_model.dart';

final bookmarkIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.bookmarksCollection)
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => doc.data()['opportunityId'] as String).toList());
});

final bookmarkedOpportunitiesProvider = StreamProvider<List<Opportunity>>((ref) {
  final idsAsync = ref.watch(bookmarkIdsProvider);
  final ids = idsAsync.value ?? [];

  if (ids.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.opportunitiesCollection)
      .where('__name__', whereIn: ids)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
          .toList());
});

final isBookmarkedProvider = FutureProvider.family<bool, String>((ref, oppId) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return false;

  final snap = await FirebaseFirestore.instance
      .collection(FirestoreConstants.bookmarksCollection)
      .where('userId', isEqualTo: user.uid)
      .where('opportunityId', isEqualTo: oppId)
      .get();

  return snap.docs.isNotEmpty;
});

final class BookmarkNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggle(String opportunityId) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.bookmarksCollection)
        .where('userId', isEqualTo: user.uid)
        .where('opportunityId', isEqualTo: opportunityId)
        .get();

    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.delete();
    } else {
      await FirebaseFirestore.instance
          .collection(FirestoreConstants.bookmarksCollection)
          .add({
        'userId': user.uid,
        'opportunityId': opportunityId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

final bookmarkProvider = NotifierProvider<BookmarkNotifier, void>(BookmarkNotifier.new);
