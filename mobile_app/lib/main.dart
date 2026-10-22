// ponytail: Standard StatefulShellRoute bottom navigation with Riverpod ProviderScope.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/hypercar_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/receipt/receipt_screen.dart';
import 'features/squads/squad_leaderboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ScrollTaxApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.speed_rounded),
                activeIcon: Icon(Icons.speed_rounded, color: HypercarColors.solarOrange),
                label: 'Tax Meter',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                activeIcon: Icon(Icons.receipt_long_rounded, color: HypercarColors.solarOrange),
                label: 'Receipt',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard_rounded),
                activeIcon: Icon(Icons.leaderboard_rounded, color: HypercarColors.solarOrange),
                label: 'Squads',
              ),
            ],
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/receipt',
              builder: (context, state) => const ReceiptScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/squads',
              builder: (context, state) => const SquadLeaderboardScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class ScrollTaxApp extends StatelessWidget {
  const ScrollTaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ScrollTax',
      debugShowCheckedModeBanner: false,
      theme: HypercarTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
