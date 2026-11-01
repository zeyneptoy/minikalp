import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/babies_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/widgets.dart';
import 'steps/birth_date_step.dart';
import 'steps/gender_step.dart';
import 'steps/name_step.dart';
import 'steps/photo_step.dart';

/// How the step-by-step profile form is being used.
enum ProfileFlowMode {
  /// First-run creation of the first baby.
  create,

  /// Adding an additional baby (multi-baby support).
  add,

  /// Editing the active baby.
  edit,
}

/// Step-by-step baby profile form.
///
/// Four full-screen steps (name → birth date → gender → photo) with a top
/// progress bar + step indicator and a large bottom action button. The step
/// widgets read and write [profileDraftProvider], so the same structure backs
/// creation, adding another baby, and editing the active baby.
class ProfileCreateScreen extends ConsumerStatefulWidget {
  const ProfileCreateScreen({super.key, this.mode = ProfileFlowMode.create});

  /// Which flow this instance drives.
  final ProfileFlowMode mode;

  bool get isEdit => mode == ProfileFlowMode.edit;

  @override
  ConsumerState<ProfileCreateScreen> createState() =>
      _ProfileCreateScreenState();
}

class _ProfileCreateScreenState extends ConsumerState<ProfileCreateScreen> {
  final PageController _pageController = PageController();
  int _step = 0;

  static const int _stepCount = 4;

  @override
  void initState() {
    super.initState();
    // Seed or reset the draft once the first frame is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(profileDraftProvider.notifier);
      final active = ref.read(babyProfileProvider);
      if (widget.isEdit && active != null) {
        notifier.seed(active);
      } else {
        notifier.reset();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Whether the current step's required input is satisfied.
  bool _isStepValid(ProfileDraft draft) {
    switch (_step) {
      case 0:
        return draft.isNameValid;
      case 1:
        return draft.isBirthDateValid;
      case 2:
        return draft.isGenderValid;
      default:
        return true; // Photo step is optional.
    }
  }

  void _back() {
    if (_step == 0) {
      // Create (first run) returns to onboarding; add/edit pop back.
      if (widget.mode != ProfileFlowMode.create && context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.onboarding);
      }
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
  }

  void _next() {
    if (_step < _stepCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    final draft = ref.read(profileDraftProvider);
    if (!draft.isBirthDateValid) return;
    final profile = draft.toProfile();
    final babies = ref.read(babiesProvider.notifier);

    if (widget.isEdit) {
      await babies.updateActive(profile);
      if (!mounted) return;
      context.canPop() ? context.pop() : context.go(AppRoutes.profile);
    } else {
      // create (first baby) or add (additional baby)
      await babies.addBaby(profile);
      if (!mounted) return;
      context.go(AppRoutes.celebration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(profileDraftProvider);
    final isLast = _step == _stepCount - 1;
    final canContinue = _isStepValid(draft);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _ProgressHeader(
                step: _step,
                stepCount: _stepCount,
                onBack: _back,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _step = i),
                  children: const [
                    NameStep(),
                    BirthDateStep(),
                    GenderStep(),
                    PhotoStep(),
                  ],
                ),
              ),
              // On the photo step, offer a skip shortcut.
              if (isLast)
                TextButton(
                  onPressed: _complete,
                  child: const Text('Şimdilik atla'),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: PrimaryButton(
                  label: isLast ? 'Tamamla' : 'Devam',
                  icon: isLast
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: canContinue ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top bar: back arrow, "Adım x / n" indicator and an animated progress bar.
class _ProgressHeader extends ConsumerWidget {
  const _ProgressHeader({
    required this.step,
    required this.stepCount,
    required this.onBack,
  });

  final int step;
  final int stepCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final progress = (step + 1) / stepCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Geri',
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.pillAll,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOut,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: colors.soft,
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Adım ${step + 1} / $stepCount',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
