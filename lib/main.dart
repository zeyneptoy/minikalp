import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/api/api_config.dart';
import 'core/constants/app_constants.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load any saved backend address before the first request.
  await ApiConfig.loadFromPrefs();
  // Load date symbols for every locale so DateFormat works in all languages.
  await initializeDateFormatting();
  // Prepare local notifications (reminders, appointments, vaccines).
  await NotificationService.init();
  runApp(const ProviderScope(child: MiniKalpApp()));
}

/// Root widget. Wires up the dynamic (gender-based) theme, the theme mode
/// (light default / dark optional) and the go_router navigation.
class MiniKalpApp extends ConsumerWidget {
  const MiniKalpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The palette is derived from the selected gender; both light and dark
    // ThemeData are rebuilt whenever it changes.
    final colors = ref.watch(appColorsProvider);
    final themeMode = ref.watch(themeModeProvider);
    // The chosen app language (null until picked on first run → device locale).
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(colors),
      darkTheme: AppTheme.dark(colors),
      themeMode: themeMode,
      // Smoothly cross-fade when the theme (light/dark or palette) changes.
      themeAnimationDuration: AppConstants.themeAnimationDuration,
      themeAnimationCurve: Curves.easeInOut,
      routerConfig: appRouter,
      locale: locale,
      supportedLocales:
          kSupportedLanguages.map((l) => l.locale).toList(growable: false),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
