import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/widgets.dart';

/// Blocking screen shown when the installed app is older than the backend's
/// minimum required version. The update button opens the correct store.
class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _openStore(BuildContext context, WidgetRef ref) async {
    final config = ref.read(appConfigDataProvider);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    final androidUrl = config?['android_store_url'] as String?;
    final iosUrl = config?['ios_store_url'] as String?;
    final url = isIOS ? (iosUrl ?? androidUrl) : (androidUrl ?? iosUrl);

    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final latest = ref.watch(appConfigDataProvider)?['latest_version'];

    // Prevent dismissing: the user must update to continue.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: colors.soft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.system_update_rounded,
                          size: 48, color: colors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Güncelleme gerekli',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Devam edebilmek için lütfen uygulamayı en son sürüme '
                    'güncelleyin.'
                    '${latest != null ? '\n\nEn son sürüm: $latest' : ''}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Güncelle',
                    icon: Icons.download_rounded,
                    onPressed: () => _openStore(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
