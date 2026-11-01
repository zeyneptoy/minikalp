import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/growth_section.dart';
import 'widgets/memory_section.dart';
import 'widgets/milestone_section.dart';
import 'widgets/teeth_section.dart';

/// Gelişim tab: growth, milestones, teething and memories.
class DevelopmentScreen extends StatelessWidget {
  const DevelopmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = <Widget>[
      Text('Gelişim', style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.lg),
      const GrowthSection(),
      const SizedBox(height: AppSpacing.xl),
      const MilestoneSection(),
      const SizedBox(height: AppSpacing.xl),
      const TeethSection(),
      const SizedBox(height: AppSpacing.xl),
      const MemorySection(),
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              190,
            ),
            children: sections
                .animate(interval: 50.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
          ),
        ),
      ),
    );
  }
}
