import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import 'forms/sleep_form.dart';
import 'forms/vomit_form.dart';
import 'sections/feeding_section.dart';
import 'sections/health_section.dart';
import 'sections/stool_section.dart';
import 'widgets/pill_segmented_control.dart';

/// Takip (tracking) tab with a pill-shaped segmented control across the top:
/// Beslenme | Kaka | Kusma | Uyku | Sağlık.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  int _segment = 0;

  static const List<String> _segments = [
    'Beslenme',
    'Kaka',
    'Kusma',
    'Uyku',
    'Sağlık',
  ];

  Widget _body() {
    switch (_segment) {
      case 0:
        return const FeedingSection();
      case 1:
        return const StoolSection();
      case 2:
        return const _CardWrapped(title: 'Kusma', child: VomitForm());
      case 3:
        return const _CardWrapped(title: 'Uyku', child: SleepForm());
      default:
        return const HealthSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Takip', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.md),
                    PillSegmentedControl(
                      segments: _segments,
                      selectedIndex: _segment,
                      onChanged: (i) => setState(() => _segment = i),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    190,
                  ),
                  children: [
                    // Re-key so content animates in on each segment change.
                    KeyedSubtree(
                      key: ValueKey(_segment),
                      child: _body(),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.04, end: 0, curve: Curves.easeOut),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps a single form in a titled glass card (for the Kusma / Uyku segments).
class _CardWrapped extends StatelessWidget {
  const _CardWrapped({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title: title),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ],
    );
  }
}
