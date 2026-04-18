import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../ui/shell/main_shell.dart';
import '../../ui/screens/dashboard/dashboard_screen.dart';
import '../../ui/screens/ledger/ledger_screen.dart';
import '../../ui/screens/seasons/seasons_screen.dart';
import '../../ui/screens/settings/settings_screen.dart';
import '../../ui/screens/analytics/analytics_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _dashboardNavigatorKey = GlobalKey<NavigatorState>();
final _ledgerNavigatorKey = GlobalKey<NavigatorState>();
final _seasonsNavigatorKey = GlobalKey<NavigatorState>();
final _settingsNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _ledgerNavigatorKey,
            routes: [
              GoRoute(
                path: '/ledger',
                builder: (context, state) => const LedgerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _seasonsNavigatorKey,
            routes: [
              GoRoute(
                path: '/seasons',
                builder: (context, state) => const SeasonsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
