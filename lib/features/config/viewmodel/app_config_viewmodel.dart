import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../common/view_model/auth_notifier.dart';
import '../model/app_config.dart';
import '../repository/app_config_repo.dart';

part 'app_config_viewmodel.g.dart';

/// The app configuration, re-fetched whenever the session changes.
///
/// `/config` answers differently with and without a student token — the
/// per-user trial fields only come back when signed in — so this watches the
/// access token and reloads on login, logout and token refresh. Without that,
/// a config fetched on the splash screen would keep reporting "no trial
/// state" for the whole session.
///
/// This provider never fails. The development flavor does not serve `/config`
/// at all, so any failure resolves to [AppConfig.fallback] — trial off, no
/// gating — rather than an error state the UI would have to handle. Locking
/// users out because a config request timed out would be far worse than
/// briefly letting them through.
@Riverpod(keepAlive: true)
class AppConfigNotifier extends _$AppConfigNotifier {
  @override
  Future<AppConfig> build() async {
    // Wait for the stored token to load so the first fetch already carries it;
    // afterwards any change to the token re-runs this build.
    await ref.watch(authNotifierProvider.future);
    return _fetch();
  }

  Future<AppConfig> _fetch() async {
    final result = await ref.read(appConfigRepoProvider).getAppConfig();
    return result.fold((_) => AppConfig.fallback, (config) => config);
  }

  /// Re-fetches the configuration, e.g. after a mock test is created or a
  /// subscription completes, to pick up the backend's updated counters.
  ///
  /// The previous value stays on screen while the request is in flight — a
  /// loading flash on the trial banner every time a counter moves would be
  /// worse than a brief moment of stale numbers.
  Future<void> refresh() async {
    state = AsyncValue.data(await _fetch());
  }
}
