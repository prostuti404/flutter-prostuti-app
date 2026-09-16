// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appConfigNotifierHash() => r'2fad9c0a3c82dafc19e1a5f9dffa2b5a3c4c9818';

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
///
/// Copied from [AppConfigNotifier].
@ProviderFor(AppConfigNotifier)
final appConfigNotifierProvider =
    AsyncNotifierProvider<AppConfigNotifier, AppConfig>.internal(
  AppConfigNotifier.new,
  name: r'appConfigNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appConfigNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppConfigNotifier = AsyncNotifier<AppConfig>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
