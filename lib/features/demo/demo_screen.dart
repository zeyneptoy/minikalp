import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/baby_profile.dart';
import '../../core/mock/mock_data.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/age_calculator.dart';
import '../../core/widgets/widgets.dart';

/// Temporary showcase screen for Round 1.
///
/// Demonstrates every reusable core widget and, most importantly, the
/// gender-driven dynamic theme: tapping the girl / boy / unspecified switcher
/// recolors the whole screen (background, blobs, buttons, charts, nav bar…)
/// with a smooth animation.
class DemoScreen extends ConsumerStatefulWidget {
  const DemoScreen({super.key});

  @override
  ConsumerState<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends ConsumerState<DemoScreen> {
  int _navIndex = 0;
  String? _photoPath;

  @override
  Widget build(BuildContext context) {
    final gender = ref.watch(genderProvider);
    final themeMode = ref.watch(themeModeProvider);
    final baby = MockData.demoBaby;
    final ageLabel = AgeCalculator.describe(baby.birthDate);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(baby, ageLabel, themeMode),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    _genderSwitcher(gender),
                    const SizedBox(height: AppSpacing.xl),
                    _quickActionsSection(),
                    const SizedBox(height: AppSpacing.xl),
                    _statsSection(),
                    const SizedBox(height: AppSpacing.xl),
                    _timerSection(),
                    const SizedBox(height: AppSpacing.xl),
                    _bannersSection(),
                    const SizedBox(height: AppSpacing.xl),
                    _buttonsAndChipsSection(context),
                    const SizedBox(height: AppSpacing.xl),
                    _timelineSection(),
                  ].animate(interval: 60.ms).fadeIn(duration: 350.ms).slideY(
                        begin: 0.08,
                        end: 0,
                        curve: Curves.easeOut,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GlassBottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          GlassNavItem(icon: Icons.home_rounded, label: 'Ana Sayfa'),
          GlassNavItem(icon: Icons.favorite_rounded, label: 'Takip'),
          GlassNavItem(icon: Icons.insights_rounded, label: 'Analiz'),
          GlassNavItem(icon: Icons.settings_rounded, label: 'Ayarlar'),
        ],
      ),
    );
  }

  // ----- Header -----

  Widget _buildHeader(BabyProfile baby, String ageLabel, ThemeMode mode) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            BabyAvatar(
              photoPath: _photoPath,
              radius: 32,
              onTap: _pickPhoto,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Merhaba, ${baby.name}',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(ageLabel, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            // Theme (day/night) toggle.
            IconButton(
              tooltip: 'Tema değiştir',
              onPressed: () =>
                  ref.read(themeModeProvider.notifier).toggle(),
              icon: Icon(
                mode == ThemeMode.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Gender switcher (proves the dynamic theme) -----

  Widget _genderSwitcher(Gender current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Tema (Cinsiyete Göre)',
          subtitle: 'Seçimi değiştirince tüm renkler animasyonla değişir.',
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final g in Gender.values)
              SoftChip(
                label: g.label,
                icon: _genderIcon(g),
                selected: current == g,
                onTap: () =>
                    ref.read(genderProvider.notifier).setGender(g),
              ),
          ],
        ),
      ],
    );
  }

  // ----- Quick actions -----

  Widget _quickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Hızlı İşlemler'),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.82,
          children: const [
            QuickActionTile(
                icon: Icons.local_drink_rounded, label: 'Emzirme'),
            QuickActionTile(icon: Icons.bedtime_rounded, label: 'Uyku'),
            QuickActionTile(icon: Icons.baby_changing_station_rounded, label: 'Bez'),
            QuickActionTile(
                icon: Icons.monitor_weight_rounded, label: 'Tartı'),
          ],
        ),
      ],
    );
  }

  // ----- Stat mini cards -----

  Widget _statsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Bugünün Özeti'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: const [
            Expanded(
              child: StatMiniCard(
                icon: Icons.local_drink_rounded,
                value: '8',
                caption: 'Bugünkü emzirme',
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatMiniCard(
                icon: Icons.bedtime_rounded,
                value: '14s 20dk',
                caption: 'Toplam uyku',
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatMiniCard(
                icon: Icons.baby_changing_station_rounded,
                value: '6',
                caption: 'Bez değişimi',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ----- Circular timer -----

  Widget _timerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Emzirme Zamanlayıcı'),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: CircularTimer(
              progress: 0.68,
              timeLabel: '12:45',
              caption: 'Hedefin %68’i',
            ),
          ),
        ),
      ],
    );
  }

  // ----- Warning banners -----

  Widget _bannersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionTitle(title: 'Bilgilendirmeler'),
        SizedBox(height: AppSpacing.sm),
        WarningBanner(
          level: WarningLevel.info,
          title: 'İpucu',
          message: 'Gece beslemelerinde koyu temayı kullanabilirsin.',
        ),
        SizedBox(height: AppSpacing.md),
        WarningBanner(
          level: WarningLevel.caution,
          title: 'Hatırlatma',
          message: 'Son tartımın üzerinden 2 hafta geçti.',
        ),
        SizedBox(height: AppSpacing.md),
        WarningBanner(
          level: WarningLevel.important,
          title: 'Dikkat',
          message: 'Yüksek ateş sürüyorsa doktoruna danışmayı unutma.',
        ),
      ],
    );
  }

  // ----- Buttons, chips, bottom sheet -----

  Widget _buttonsAndChipsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Butonlar ve Etiketler'),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: 'Kayıt Ekle',
          icon: Icons.add_rounded,
          onPressed: () => _showDemoSheet(context),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'Alt Sayfayı Aç',
          icon: Icons.open_in_full_rounded,
          outlined: true,
          onPressed: () => _showDemoSheet(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: const [
            SoftChip(label: 'Emzirme', icon: Icons.local_drink_rounded),
            SoftChip(
                label: 'Uyku',
                icon: Icons.bedtime_rounded,
                selected: true),
            SoftChip(label: 'Sağlık', icon: Icons.favorite_rounded),
            SoftChip(label: 'Gelişim', icon: Icons.auto_graph_rounded),
          ],
        ),
      ],
    );
  }

  // ----- Timeline -----

  Widget _timelineSection() {
    final items = MockData.todayTimeline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Bugünkü Akış', actionLabel: 'Tümü'),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                TimelineItem(
                  icon: _activityIcon(items[i].icon),
                  title: items[i].title,
                  subtitle: items[i].subtitle,
                  time: items[i].time,
                  isFirst: i == 0,
                  isLast: i == items.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ----- Helpers -----

  void _showDemoSheet(BuildContext context) {
    GlassBottomSheet.show(
      context,
      title: 'Kayıt Türü Seç',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              SoftChip(label: 'Emzirme', icon: Icons.local_drink_rounded),
              SoftChip(label: 'Uyku', icon: Icons.bedtime_rounded),
              SoftChip(label: 'Bez', icon: Icons.baby_changing_station_rounded),
              SoftChip(label: 'Kusma', icon: Icons.sick_rounded),
              SoftChip(label: 'Sağlık', icon: Icons.favorite_rounded),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Kaydet',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
      );
      if (file != null && mounted) {
        setState(() => _photoPath = file.path);
      }
    } catch (_) {
      // Picking a photo can fail on platforms without a gallery (e.g. some
      // desktop targets); the prototype simply ignores that here.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf seçilemedi.')),
        );
      }
    }
  }

  IconData _genderIcon(Gender g) {
    switch (g) {
      case Gender.girl:
        return Icons.female_rounded;
      case Gender.boy:
        return Icons.male_rounded;
      case Gender.unspecified:
        return Icons.help_outline_rounded;
    }
  }

  IconData _activityIcon(ActivityIcon a) {
    switch (a) {
      case ActivityIcon.feeding:
        return Icons.local_drink_rounded;
      case ActivityIcon.diaper:
        return Icons.baby_changing_station_rounded;
      case ActivityIcon.sleep:
        return Icons.bedtime_rounded;
      case ActivityIcon.vomit:
        return Icons.sick_rounded;
      case ActivityIcon.health:
        return Icons.favorite_rounded;
      case ActivityIcon.growth:
        return Icons.monitor_weight_rounded;
    }
  }
}

/// App name convenience accessor so the demo title stays in sync.
const String demoTitle = AppConstants.appName;
