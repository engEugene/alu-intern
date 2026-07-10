import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_constants.dart';
import '../models/app_user.dart';

export '../models/app_user.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

final class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<User?>? _subscription;

  @override
  AuthState build() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    ref.onDispose(_subscription!.cancel);
    return const AuthState();
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        final user = AppUser.fromMap(firebaseUser.uid, doc.data()!);
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        final newUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
        );
        await FirebaseFirestore.instance
            .collection(FirestoreConstants.usersCollection)
            .doc(firebaseUser.uid)
            .set(newUser.toMap());
        state = AuthState(status: AuthStatus.authenticated, user: newUser);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: AppUser.fromFirebase(firebaseUser),
      );
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String fullname,
    required String username,
    UserRole role = UserRole.student,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection(FirestoreConstants.usersCollection)
          .doc(cred.user!.uid)
          .set(AppUser(
            uid: cred.user!.uid,
            email: email,
            displayName: fullname,
            username: username,
            role: role,
          ).toMap());
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> updateUserInFirestore(Map<String, dynamic> updates) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection(FirestoreConstants.usersCollection)
        .doc(currentUser.uid)
        .update(updates);

    final doc = await FirebaseFirestore.instance
        .collection(FirestoreConstants.usersCollection)
        .doc(currentUser.uid)
        .get();

    if (doc.exists) {
      state = state.copyWith(user: AppUser.fromMap(currentUser.uid, doc.data()!));
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  static String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
