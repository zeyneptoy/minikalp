import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/widgets.dart';

/// The app's main navigation area: a glass pill with the five tabs plus a
/// prominent floating "+" quick-add button centered above it.
///
/// Reuses the Round 1 [GlassBottomNavBar] for the tabs and stacks the add
/// button above it so no tab is obscured.
class MainBottomBar extends ConsumerWidget {
  const MainBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAdd,
  });

  /// Five destinations: Ana Sayfa, Takip, Analiz, Gelişim, Profil.
  static const List<GlassNavItem> items = [
    GlassNavItem(icon: Icons.home_rounded, label: 'Ana Sayfa'),
    GlassNavItem(icon: Icons.favorite_rounded, label: 'Takip'),
    GlassNavItem(icon: Icons.insights_rounded, label: 'Analiz'),
    GlassNavItem(icon: Icons.eco_rounded, label: 'Gelişim'),
    GlassNavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating quick-add button, centered above the bar.
        _AddButton(onTap: onAdd),
        const SizedBox(height: AppSpacing.sm),
        GlassBottomNavBar(
          items: items,
          currentIndex: currentIndex,
          onTap: onTap,
        ),
      ],
    );
  }
}

/// The circular gradient "+" button with a press animation.
class _AddButton extends ConsumerStatefulWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  ConsumerState<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends ConsumerState<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, colors.accent],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
