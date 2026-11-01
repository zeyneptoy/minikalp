import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/info_article.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/widgets.dart';

/// Reader for a single informational article: a header image at the top with
/// the title and body text below.
class InfoArticleScreen extends ConsumerWidget {
  const InfoArticleScreen({super.key, required this.article});

  final InfoArticle article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Geri',
                    ),
                    Expanded(
                      child: Text('Bilgilendirme',
                          style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                  children: [
                    // Header image.
                    ClipRRect(
                      borderRadius: AppRadius.cardAll,
                      child: _HeaderImage(
                        url: article.imageUrl,
                        soft: colors.soft,
                        primary: colors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      article.title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      article.body,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
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

class _HeaderImage extends StatelessWidget {
  const _HeaderImage({
    required this.url,
    required this.soft,
    required this.primary,
  });

  final String? url;
  final Color soft;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: 200,
      color: soft,
      child: Icon(Icons.menu_book_rounded, size: 56, color: primary),
    );

    if (url == null || url!.isEmpty) return fallback;

    return Image.network(
      url!,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 200,
          color: soft,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        );
      },
    );
  }
}
