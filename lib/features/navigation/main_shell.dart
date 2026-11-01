import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../tracking/record_sheets.dart';
import 'main_bottom_bar.dart';
import 'quick_add_sheet.dart';

/// Hosts the five main tabs inside a [StatefulNavigationShell] and renders the
/// floating glass bottom bar with the central quick-add button.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  /// The go_router shell that keeps each tab's state in an IndexedStack.
  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    // `initialLocation: true` pops to the branch root when re-tapping its tab.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _onAdd(BuildContext context) async {
    // First pick a record type, then open its form as a glass bottom sheet.
    final type = await QuickAddSheet.show(context);
    if (type != null && context.mounted) {
      await RecordSheets.open(context, type);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Let the page content flow behind the floating bar.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: MainBottomBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        onAdd: () => _onAdd(context),
      ),
    );
  }
}
