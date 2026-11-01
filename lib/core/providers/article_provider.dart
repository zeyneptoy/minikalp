import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';

/// The age-appropriate article for the given baby's current month, fetched
/// from the backend. Returns null if none is available / offline.
final babyArticleProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, int>((ref, babyId) async {
  final api = ref.read(apiClientProvider);
  return api.articleForBaby(babyId);
});
