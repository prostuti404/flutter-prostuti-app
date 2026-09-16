// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_control.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$accessControlHash() => r'40b1784eb4196ebb4d3739fa29648bdc19b80c05';

/// Decides what a user may reach before they subscribe.
///
/// The backend is the source of truth: `/config`, fetched with the student's
/// token, reports `isTrialActive`, `trialDaysLeft` and per-feature usage
/// counters, and those are used as-is. The two client-side compromises below
/// only apply when the server sends none of that (an older deployment, or a
/// config fetched before the token was available):
///
/// * **The trial clock is anchored to the student's `createdAt`** from
///   `/user/profile`. Accounts older than the config document predate the
///   feature and fall back to a device-local first-seen timestamp instead.
/// * **Usage against `featureLimits` is counted on the device**
///   ([TrialStorage]). It survives logout but not a data wipe, and a second
///   device starts fresh.
///
/// Nothing here is enforced by the API, so treat it as a product gate, not a
/// security boundary.
///
/// Copied from [AccessControl].
@ProviderFor(AccessControl)
final accessControlProvider =
    AutoDisposeAsyncNotifierProvider<AccessControl, TrialStatus>.internal(
  AccessControl.new,
  name: r'accessControlProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$accessControlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AccessControl = AutoDisposeAsyncNotifier<TrialStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
