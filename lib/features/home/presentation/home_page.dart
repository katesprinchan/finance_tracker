import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/core/presentation/drawer.dart';
import 'package:finance_tracker/features/categories/presentation/page/categorie_vm.dart';
import 'package:finance_tracker/routing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  final CategoryViewModel vm;
  final StatefulNavigationShell child;
  const HomePage({super.key, required this.child, required this.vm});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CategoryViewModel get vm => widget.vm;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitleByIndex(context, widget.child.currentIndex),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      drawer: MainDrawer(onSettingsTap: () {
        widget.vm.onSettingsTap(context);
      }),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.child.currentIndex,
        onTap: (value) => _onBottomBarItemTap(value, context),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            label: S.of(context).categories,
            activeIcon: const Icon(Icons.grid_view),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: S.of(context).operations,
            activeIcon: const Icon(Icons.account_balance_wallet),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            label: S.of(context).analytics,
            activeIcon: const Icon(Icons.bar_chart),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
            label: S.of(context).profile,
            activeIcon: const Icon(Icons.account_circle),
          ),
        ],
      ),
    );
  }
}

_onBottomBarItemTap(int value, BuildContext context) {
  switch (value) {
    case 0:
      return context.go(AppRouteList.categoriePage);
    case 1:
      return context.go(AppRouteList.operationListPage);
    case 2:
      return context.go(AppRouteList.analyticPage);
    case 3:
      return context.go(AppRouteList.profilePage);
  }
}

String _getTitleByIndex(BuildContext context, int index) {
  switch (index) {
    case 0:
      return S.of(context).categories;
    case 1:
      return S.of(context).operations;
    case 2:
      return S.of(context).analytics;
    case 3:
      return S.of(context).profile;
    default:
      return '';
  }
}
