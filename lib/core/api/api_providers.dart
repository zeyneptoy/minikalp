import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_provider.dart';
import 'api_client.dart';

/// The single shared API client for the app.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// App config (versions + store URLs) fetched by the splash screen and read by
/// the force-update screen. Null until the splash loads it.
final appConfigDataProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// The backend id of the currently active baby, or null when none has been
/// synced yet. Data notifiers watch this to know which baby to hydrate from
/// and write to.
final currentBabyIdProvider = Provider<int?>((ref) {
  return ref.watch(babyProfileProvider)?.remoteId;
});
