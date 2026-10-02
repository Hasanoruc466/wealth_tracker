import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/market_lifecycle.dart';
import 'debts/debts_page.dart';
import 'markets/markets_page.dart';
import 'portfolio/portfolio_page.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final index = ref.watch(homeTabProvider);

    return MarketLifecycle(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          body: IndexedStack(
            index: index,
            children: const [PortfolioPage(), DebtsPage(), MarketsPage()],
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.palette.border)),
            ),
            child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected:
                  (i) => ref.read(homeTabProvider.notifier).state = i,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline_rounded),
                  selectedIcon: Icon(Icons.pie_chart_rounded),
                  label: 'Portföy',
                ),
                NavigationDestination(
                  icon: Icon(Icons.handshake_outlined),
                  selectedIcon: Icon(Icons.handshake_rounded),
                  label: 'Borçlar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.show_chart_rounded),
                  label: 'Piyasalar',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
