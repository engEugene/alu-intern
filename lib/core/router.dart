import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shared/features/auth/providers/auth_provider.dart';
import '../shared/features/auth/screens/login_screen.dart';
import '../shared/features/auth/screens/register_screen.dart';
import '../student/features/onboarding/screens/skill_selection_screen.dart';
import '../startup/features/startups/screens/startup_create_screen.dart';
import '../startup/features/dashboard/screens/startup_dashboard_screen.dart';
import '../student/features/home/screens/home_screen.dart';
import '../student/features/opportunities/screens/opportunity_list_screen.dart';
import '../startup/features/opportunities/screens/startup_opportunities_screen.dart';
import '../student/features/opportunities/screens/opportunity_detail_screen.dart';
import '../startup/features/opportunities/screens/opportunity_create_screen.dart';
import '../startup/features/applications/screens/startup_applicants_screen.dart';
import '../student/features/applications/screens/application_list_screen.dart';
import '../student/features/applications/screens/application_create_screen.dart';
import '../student/features/applications/screens/application_detail_screen.dart';
import '../student/features/bookmarks/screens/bookmark_list_screen.dart';
import '../shared/features/profile/screens/profile_screen.dart';
import '../shared/features/admin/screens/verification_screen.dart';
import '../shared/widgets/nav_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final user = authState.user;
      final path = state.matchedLocation;

      final publicRoutes = ['/login', '/register'];
      final onboardingRoutes = ['/onboarding', '/startup/onboarding'];

      if (!isLoggedIn && !publicRoutes.contains(path)) {
        return '/login';
      }
      if (isLoggedIn && publicRoutes.contains(path)) {
        return '/';
      }
      if (isLoggedIn && user != null && !user.onboardingComplete && !onboardingRoutes.contains(path)) {
        return switch (user.role) {
          UserRole.startup => '/startup/onboarding',
          _ => '/onboarding',
        };
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const SkillSelectionScreen(),
      ),
      GoRoute(
        path: '/startup/onboarding',
        builder: (_, __) => const StartupCreateScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => NavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) {
                  final role = authState.user?.role;
                  return switch (role) {
                    UserRole.startup => const StartupDashboardScreen(),
                    UserRole.admin => const VerificationScreen(),
                    _ => const HomeScreen(),
                  };
                },
                routes: [
              GoRoute(
                path: '/opportunities',
                builder: (_, __) {
                  final role = authState.user?.role;
                  return switch (role) {
                    UserRole.startup => const StartupOpportunitiesScreen(),
                    _ => const OpportunityListScreen(),
                  };
                },
                routes: [
                      GoRoute(
                        path: 'create',
                        builder: (_, __) => const OpportunityCreateScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => OpportunityDetailScreen(
                          id: state.pathParameters['id']!,
                          applicationStatus: state.uri.queryParameters['status'],
                        ),
                        routes: [
                          GoRoute(
                            path: 'apply',
                            builder: (_, state) => ApplicationCreateScreen(
                              opportunityId: state.pathParameters['id']!,
                              opportunityTitle: '',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/applications',
                builder: (_, __) {
                  final role = authState.user?.role;
                  return switch (role) {
                    UserRole.startup => const StartupApplicantsScreen(),
                    _ => const ApplicationListScreen(),
                  };
                },
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => ApplicationDetailScreen(
                      applicationId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookmarks',
                builder: (_, __) {
                  final role = authState.user?.role;
                  return switch (role) {
                    UserRole.startup => const StartupOpportunitiesScreen(),
                    _ => const BookmarkListScreen(),
                  };
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) {
                  return const ProfileScreen();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
