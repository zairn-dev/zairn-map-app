import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/providers/auth_state_provider.dart';
import '../../features/friends/presentation/friends_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/posts/presentation/feed_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../navigation/app_shell.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => SplashScreen(
          onComplete: () {
            final session = ref.read(currentSessionProvider);
            if (session == null) {
              context.go(AppRoutes.auth);
              return;
            }
            context.go(AppRoutes.map);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) =>
            AuthScreen(onAuthenticated: () => context.go(AppRoutes.onboarding)),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) =>
            OnboardingScreen(onContinue: () => context.go(AppRoutes.map)),
      ),
      // Settings remains a push route (accessed from Profile)
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      // 4-tab shell: Map(0), Feed(1), Friends(2), Profile(3)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.map,
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.feed,
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.friends,
                builder: (context, state) => const FriendsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
