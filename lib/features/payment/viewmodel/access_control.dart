import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../common/helpers/functions.dart';
import '../../../core/services/trial_storage.dart';
import '../../config/model/app_config.dart';
import '../../config/viewmodel/app_config_viewmodel.dart';
import '../repository/payment_repo.dart';

part 'access_control.g.dart';

/// Why a user currently has (or lacks) access to a feature.
enum AccessTier {
  /// Paid subscription is active — everything is open.
  subscribed,

  /// Inside the free-trial window.
  trial,

  /// Trial window has passed without a subscription.
  expired,

  /// Gating is not in force: the backend has trials switched off, or the config
  /// could not be loaded. The app behaves as it did before the trial existed.
  unrestricted,
}

/// The reason behind a single [FeatureAccess] answer, so the UI can say
/// something more useful than "locked".
enum AccessReason {
  subscribed,
  unrestricted,

  /// Free during the trial, and the user is still under the cap.
  withinTrial,

  /// Free during the trial, but the cap has been spent.
  limitReached,

  /// The trial window has closed.
  trialExpired,

  /// The backend does not list this feature as free during the trial.
  notIncluded,
}

/// The answer for one feature at one moment.
class FeatureAccess {
  final bool allowed;
  final AccessReason reason;

  /// How many uses have been recorded on this device, when the feature is
  /// capped. Null when the feature is uncapped or access does not depend on it.
  final int? used;

  /// The cap from `featureLimits`, or null when the backend sets none.
  final int? limit;

  const FeatureAccess({
    required this.allowed,
    required this.reason,
    this.used,
    this.limit,
  });

  /// Uses left before the cap bites, or null when uncapped.
  int? get remaining =>
      (limit == null || used == null) ? null : (limit! - used!).clamp(0, limit!);
}

/// A snapshot of the user's position in the pre-subscription journey.
class TrialStatus {
  final AccessTier tier;
  final AppConfig config;

  /// When the trial window closes. Null unless [tier] is trial or expired.
  final DateTime? trialEndsAt;

  /// Days left as the backend reported them, when it did. Preferred over the
  /// [trialEndsAt] arithmetic because the server's clock is the one that
  /// actually decides.
  final int? reportedDaysLeft;

  /// Usage per feature for the current user — the backend's counters when it
  /// reports them, otherwise what this device has recorded.
  final Map<FreeFeature, int> usage;

  const TrialStatus({
    required this.tier,
    required this.config,
    this.trialEndsAt,
    this.reportedDaysLeft,
    this.usage = const {},
  });

  /// Whole days left in the trial, floored at zero.
  int get daysRemaining {
    if (reportedDaysLeft != null) return reportedDaysLeft!.clamp(0, 1 << 31);
    if (trialEndsAt == null) return 0;
    final left = trialEndsAt!.difference(DateTime.now()).inMinutes;
    return left <= 0 ? 0 : (left / (60 * 24)).ceil();
  }

  /// Whether the subscription prompt is relevant to this user at all.
  bool get shouldPromptSubscription =>
      tier == AccessTier.expired || tier == AccessTier.trial;

  /// Resolves access to [feature] for the current tier.
  FeatureAccess accessTo(FreeFeature feature) {
    switch (tier) {
      case AccessTier.subscribed:
        return const FeatureAccess(
            allowed: true, reason: AccessReason.subscribed);

      case AccessTier.unrestricted:
        return const FeatureAccess(
            allowed: true, reason: AccessReason.unrestricted);

      case AccessTier.expired:
        return const FeatureAccess(
            allowed: false, reason: AccessReason.trialExpired);

      case AccessTier.trial:
        if (!config.isFree(feature)) {
          return const FeatureAccess(
              allowed: false, reason: AccessReason.notIncluded);
        }

        final limit = config.limitFor(feature);
        // No cap in `featureLimits` means unlimited during the trial — which is
        // the case for "Recorded Videos".
        if (limit == null) {
          return const FeatureAccess(
              allowed: true, reason: AccessReason.withinTrial);
        }

        final used = usage[feature] ?? 0;
        return FeatureAccess(
          allowed: used < limit,
          reason: used < limit
              ? AccessReason.withinTrial
              : AccessReason.limitReached,
          used: used,
          limit: limit,
        );
    }
  }
}

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
@riverpod
class AccessControl extends _$AccessControl {
  String? _userId;

  /// Whether the current snapshot came from the backend's counters (as
  /// opposed to [TrialStorage]). Decides what [recordUsage] does.
  bool _serverTracked = false;

  @override
  Future<TrialStatus> build() async {
    final config = await ref.watch(appConfigNotifierProvider.future);

    // Trials switched off at the backend, or config unreachable — behave
    // exactly as the app did before this feature landed.
    if (!config.isTrialEnabled || config.freeTrialDays <= 0) {
      return TrialStatus(tier: AccessTier.unrestricted, config: config);
    }

    final profileResult =
        await ref.read(paymentRepoProvider).getStudentProfile();

    // Fail open throughout: anything we cannot read must not lock a user out.
    final profile = profileResult.fold((_) => null, (r) => r);
    final data = profile?.data;
    if (data == null) {
      return TrialStatus(tier: AccessTier.unrestricted, config: config);
    }

    final userId = data.studentId ?? data.userId ?? data.sId;
    if (userId == null) {
      return TrialStatus(tier: AccessTier.unrestricted, config: config);
    }
    _userId = userId;

    // Subscription is checked before anything the trial fields say: whether
    // the backend's `isTrialActive` accounts for a paid plan is not something
    // to bet a paying user's access on.
    if (data.subscriptionStartDate != null &&
        data.subscriptionEndDate != null &&
        HelperFunc.isUserSubscribed(
          data.subscriptionStartDate!,
          data.subscriptionEndDate!,
        )) {
      // Clear the device's trial bookkeeping the moment a subscription is
      // active, so that a later lapse starts from a clean slate rather than an
      // exhausted one. This provider is autoDispose, so it re-runs (and picks
      // up a just-completed purchase) the next time a gated screen is opened.
      await ref.read(trialStorageProvider).clearFor(userId);
      return TrialStatus(tier: AccessTier.subscribed, config: config);
    }

    if (config.hasUserTrialState) {
      _serverTracked = true;
      return _fromServer(config);
    }

    _serverTracked = false;
    final trialStart =
        await _resolveTrialStart(userId, data.createdAt, config: config);
    final trialEnd = trialStart.add(Duration(days: config.freeTrialDays));

    if (!trialEnd.isAfter(DateTime.now())) {
      return TrialStatus(
        tier: AccessTier.expired,
        config: config,
        trialEndsAt: trialEnd,
      );
    }

    final storage = ref.read(trialStorageProvider);
    final usage = <FreeFeature, int>{};
    for (final feature in FreeFeature.values) {
      usage[feature] = await storage.usage(userId, feature);
    }

    return TrialStatus(
      tier: AccessTier.trial,
      config: config,
      trialEndsAt: trialEnd,
      usage: usage,
    );
  }

  /// Builds the snapshot straight from the backend's per-user fields.
  ///
  /// `trialEndsAt` is derived from `trialDaysLeft` only so callers that look
  /// at the date keep working; [TrialStatus.daysRemaining] reads the reported
  /// number directly.
  TrialStatus _fromServer(AppConfig config) {
    final daysLeft = config.trialDaysLeft ?? 0;
    final trialEnd = DateTime.now().add(Duration(days: daysLeft));

    if (config.isTrialActive != true) {
      return TrialStatus(
        tier: AccessTier.expired,
        config: config,
        trialEndsAt: trialEnd,
        reportedDaysLeft: daysLeft,
      );
    }

    return TrialStatus(
      tier: AccessTier.trial,
      config: config,
      trialEndsAt: trialEnd,
      reportedDaysLeft: daysLeft,
      usage: {
        for (final feature in FreeFeature.values)
          feature: config.usedFor(feature) ?? 0,
      },
    );
  }

  /// Picks the moment the user's trial clock started.
  ///
  /// Only used when the backend reports no per-user trial state.
  ///
  /// Prefers the server's account-creation date — the only anchor that survives
  /// a reinstall and holds across devices. Falls back to a device-local
  /// first-seen timestamp when `createdAt` is missing, or when the account
  /// predates the config document (those users would otherwise be born already
  /// expired, through no fault of their own).
  ///
  /// Caveat worth knowing: if the config document is ever recreated its
  /// `createdAt` moves forward, so legacy accounts re-anchor locally and get one
  /// more trial. That errs towards access, which is the direction this whole
  /// path errs in.
  Future<DateTime> _resolveTrialStart(
    String userId,
    String? createdAtRaw, {
    required AppConfig config,
  }) async {
    final storage = ref.read(trialStorageProvider);
    final createdAt = DateTime.tryParse(createdAtRaw ?? '');

    if (createdAt == null) return storage.firstSeenAt(userId);

    final epoch = config.configCreatedAt;
    if (epoch != null && createdAt.isBefore(epoch)) {
      return storage.firstSeenAt(userId);
    }

    return createdAt;
  }

  /// Records one use of [feature] and refreshes the snapshot.
  ///
  /// Call after the action succeeded — a failed request should not cost the
  /// user an allowance. No-op unless the user is inside a trial and the feature
  /// is actually capped.
  ///
  /// When the backend is counting, the number is bumped locally so the banner
  /// moves at once, then `/config` is re-fetched to replace it with the
  /// server's own figure (this provider watches the config, so the refetch
  /// rebuilds the snapshot). Otherwise the device-local counter is used.
  Future<void> recordUsage(FreeFeature feature) async {
    final current = state.valueOrNull;
    final userId = _userId;
    if (current == null || userId == null) return;
    if (current.tier != AccessTier.trial) return;
    if (current.config.limitFor(feature) == null) return;

    final int next;
    if (_serverTracked) {
      next = (current.usage[feature] ?? 0) + 1;
    } else {
      next = await ref.read(trialStorageProvider).recordUsage(userId, feature);
    }

    state = AsyncValue.data(TrialStatus(
      tier: current.tier,
      config: current.config,
      trialEndsAt: current.trialEndsAt,
      reportedDaysLeft: current.reportedDaysLeft,
      usage: {...current.usage, feature: next},
    ));

    if (_serverTracked) {
      // Not awaited: callers navigate as soon as this returns, and the
      // config notifier is keepAlive so the refetch outlives this provider.
      unawaited(ref.read(appConfigNotifierProvider.notifier).refresh());
    }
  }
}
