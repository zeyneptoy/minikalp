import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/analytics_screen.dart';
import '../../features/demo/demo_screen.dart';
import '../../features/development/development_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/language/language_screen.dart';
import '../../features/navigation/main_shell.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/celebration_screen.dart';
import '../../features/profile/profile_create_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/info_page.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tracking/tracking_screen.dart';
import '../../features/update/force_update_screen.dart';

/// Named route paths. Centralized so screens never hardcode strings.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String language = '/language';
  static const String forceUpdate = '/force-update';
  static const String onboarding = '/onboarding';
  static const String profileCreate = '/profile/create';
  static const String profileEdit = '/profile/edit';
  static const String profileAdd = '/profile/add';
  static const String celebration = '/celebration';
  static const String privacy = '/settings/privacy';
  static const String disclaimer = '/settings/disclaimer';

  // Main shell tabs.
  static const String home = '/home';
  static const String tracking = '/tracking';
  static const String analytics = '/analytics';
  static const String development = '/development';
  static const String profile = '/profile';

  // Round 1 widget gallery, kept for reference during development.
  static const String demo = '/demo';
}

/// Keys so the shell and its branches have stable navigators.
final GlobalKey<NavigatorState> _rootKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app's [GoRouter].
///
/// Flow: splash → (onboarding → profile create → celebration) → main shell.
/// The five main tabs live inside a [StatefulShellRoute] so each keeps its own
/// navigation state in an IndexedStack.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.language,
      name: 'language',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: AppRoutes.forceUpdate,
      name: 'forceUpdate',
      builder: (context, state) => const ForceUpdateScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileCreate,
      name: 'profileCreate',
      builder: (context, state) => const ProfileCreateScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileEdit,
      name: 'profileEdit',
      builder: (context, state) =>
          const ProfileCreateScreen(mode: ProfileFlowMode.edit),
    ),
    GoRoute(
      path: AppRoutes.profileAdd,
      name: 'profileAdd',
      builder: (context, state) =>
          const ProfileCreateScreen(mode: ProfileFlowMode.add),
    ),
    GoRoute(
      path: AppRoutes.celebration,
      name: 'celebration',
      builder: (context, state) => const CelebrationScreen(),
    ),
    GoRoute(
      path: AppRoutes.privacy,
      name: 'privacy',
      builder: (context, state) => const PrivacyScreen(),
    ),
    GoRoute(
      path: AppRoutes.disclaimer,
      name: 'disclaimer',
      builder: (context, state) => const DisclaimerScreen(),
    ),
    GoRoute(
      path: AppRoutes.demo,
      name: 'demo',
      builder: (context, state) => const DemoScreen(),
    ),
    // Main app shell with the five tabs.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.tracking,
              name: 'tracking',
              builder: (context, state) => const TrackingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.analytics,
              name: 'analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.development,
              name: 'development',
              builder: (context, state) => const DevelopmentScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
