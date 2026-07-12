import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';
import '../../../../shared/models/startup_model.dart';

final currentStartupProvider = StreamProvider<Startup?>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value(null);

  final startupId = user.startupId;
  if (startupId != null && startupId.isNotEmpty) {
    return FirebaseFirestore.instance
        .collection(FirestoreConstants.startupsCollection)
        .doc(startupId)
        .snapshots()
        .map((doc) => doc.exists ? Startup.fromMap(doc.id, doc.data()!) : null);
  }

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.startupsCollection)
      .where('ownerId', isEqualTo: user.uid)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty ? null : Startup.fromMap(snap.docs.first.id, snap.docs.first.data()));
});

/// Merges up to three Firestore snapshot queries into a single stream of
/// combined application documents.  Each query is a simple
/// `where('field', '==', value)` that Firestore can statically verify against
/// the security rules; `whereIn` with mixed UID / doc-ID values cannot be
/// verified because the rule's `get()` call on the doc-ID branch is not
/// decidable from the query shape alone.
Stream<List<Map<String, dynamic>>> startupApplicationsStream(String uid, {String? startupDocId}) {
  final controller = StreamController<List<Map<String, dynamic>>>();
  QuerySnapshot? lastOwner;
  QuerySnapshot? lastUid;
  QuerySnapshot? lastDocId;

  List<Map<String, dynamic>> combine() {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final snap in [lastOwner, lastUid, lastDocId]) {
      if (snap == null) continue;
      for (final doc in snap.docs) {
        if (seen.add(doc.id)) {
          final entry = <String, dynamic>{'id': doc.id};
          final raw = doc.data() as Map<String, dynamic>?;
          if (raw != null) {
            for (final e in raw.entries) {
              entry[e.key] = e.value;
            }
          }
          result.add(entry);
        }
      }
    }
    result.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      return bTime.compareTo(aTime);
    });
    return result;
  }

  void emit() {
    controller.add(combine());
  }

  final ownerSub = FirebaseFirestore.instance
      .collection(FirestoreConstants.applicationsCollection)
      .where('ownerId', isEqualTo: uid)
      .snapshots()
      .listen((snap) {
        lastOwner = snap;
        emit();
      }, onError: controller.addError);

  final uidSub = FirebaseFirestore.instance
      .collection(FirestoreConstants.applicationsCollection)
      .where('startupId', isEqualTo: uid)
      .snapshots()
      .listen((snap) {
        lastUid = snap;
        emit();
      }, onError: controller.addError);

  if (startupDocId != null && startupDocId.isNotEmpty && startupDocId != uid) {
    final docIdSub = FirebaseFirestore.instance
        .collection(FirestoreConstants.applicationsCollection)
        .where('startupId', isEqualTo: startupDocId)
        .snapshots()
        .listen((snap) {
          lastDocId = snap;
          emit();
        }, onError: controller.addError);

    void cancelDocId() => docIdSub.cancel();
    controller.onCancel = () {
      ownerSub.cancel();
      uidSub.cancel();
      docIdSub.cancel();
    };
  } else {
    controller.onCancel = () {
      ownerSub.cancel();
      uidSub.cancel();
    };
  }

  return controller.stream;
}

/// Resolves the set of `startupId` values used to query opportunities.
/// Opportunities use an open read rule (`allow read: if request.auth != null`)
/// so `whereIn` remains safe here.
Future<Set<String>> resolveStartupIds(Ref ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return {};

  final ids = <String>{user.uid};

  if (user.startupId != null && user.startupId!.isNotEmpty) {
    ids.add(user.startupId!);
  } else {
    final startup = await ref.read(currentStartupProvider.future);
    if (startup != null) ids.add(startup.id);
  }

  ids.removeWhere((id) => id.isEmpty);
  return ids;
}
