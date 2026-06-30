import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';

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

  void _onAuthChanged(User? firebaseUser) {
    if (firebaseUser == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    } else {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: AppUser.fromFirebase(firebaseUser),
      );
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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
