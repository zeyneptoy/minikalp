import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../models/info_article.dart';

/// Informational articles for the home screen (public endpoint).
final infoArticlesProvider =
    FutureProvider.autoDispose<List<InfoArticle>>((ref) async {
  final rows = await ref.read(apiClientProvider).infoArticles();
  return rows
      .map((e) => InfoArticle.fromJson(e as Map<String, dynamic>))
      .toList();
});
