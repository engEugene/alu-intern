import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final path = state.matchedLocation;

      if (isLoggedIn && (path == '/login' || path == '/register')) {
        return '/';
      }
      if (!isLoggedIn && path == '/') {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    ],
  );
});
