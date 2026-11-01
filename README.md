# MinikNot

A calm, mother-friendly baby tracking app (ages 0–12 months) — **UI-only prototype**.
All text is Turkish; all data is local mock data (no backend, API, database or auth).

> Temporary product name. It is defined once in
> [`lib/core/constants/app_constants.dart`](lib/core/constants/app_constants.dart)
> as `AppConstants.appName` — change it there to rename the app everywhere.

## Round 1 — what's included

- **Theme system** (`core/theme`): gender-based dynamic palette (`AppThemeColors`),
  Material 3 light (**default**) + dark themes, spacing/radius scales, and Riverpod
  providers (`genderProvider`, `appColorsProvider`, `themeModeProvider`).
- **Gender-driven theme**: Girl → pink, Boy → blue, Unspecified → orange. Changing
  the gender recolors the whole app (background, blobs, buttons, chips, charts,
  nav bar, accents) with a smooth animation.
- **Age calculator** (`core/utils/age_calculator.dart`): pure, tested function →
  `"18 günlük"`, `"2 ay 14 günlük"`, `"12 aylık"`.
- **Model** (`core/models/baby_profile.dart`): `BabyProfile` + `Gender` enum.
- **Reusable glass widgets** (`core/widgets`): `GlassCard`, `AppBackground`,
  `PrimaryButton`, `SoftChip`, `QuickActionTile`, `StatMiniCard`, `WarningBanner`
  (info / caution / important), `TimelineItem`, `CircularTimer`, `BabyAvatar`,
  `SectionTitle`, `GlassBottomSheet`, `GlassBottomNavBar`.
- **Demo screen** (`features/demo/demo_screen.dart`): showcases every widget and a
  girl/boy/unspecified switcher that proves the dynamic theme, plus a day/night
  theme toggle.
- **App shell**: `ProviderScope`, `go_router` skeleton, Turkish localization.

## Folder structure

```
lib/
  core/
    constants/   app_constants.dart        (app name, durations)
    theme/       app_colors, app_theme, app_spacing, app_radius, theme_provider
    utils/       age_calculator.dart
    models/      baby_profile.dart
    widgets/     all reusable glass widgets (+ widgets.dart barrel)
    mock/        mock_data.dart
    router/      app_router.dart
  features/
    demo/        demo_screen.dart          (Round 1 showcase)
    onboarding/ profile/ home/ tracking/ analytics/ growth/ development/ settings/
                 (placeholders wired into the router for later rounds)
  main.dart
```

## Run

```bash
flutter pub get
flutter run
```

Then use the **Kız / Erkek / Belirtilmedi** chips to watch the theme change, and
the sun/moon icon in the header to toggle dark mode.

## Verify

```bash
flutter analyze
flutter test
```

Both are clean (`No issues found!`, all age-calculator tests pass).
