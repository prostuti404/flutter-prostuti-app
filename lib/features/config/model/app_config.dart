/// The configuration served by `GET /api/v1/config`.
///
/// Two layers share one document. The global part (trial switch, window,
/// free features, limits, support number) is the same for everyone. When the
/// request carries a student token the backend also appends that student's
/// own trial state — [isTrialActive], [trialDaysLeft], [mockTestsUsed],
/// [liveClassesUsed] — which [AccessControl] uses in place of the device-local
/// bookkeeping it previously had to keep.
class AppConfig {
  final bool isTrialEnabled;
  final int freeTrialDays;

  /// Features the backend advertises as free during the trial, normalised
  /// from the API's `MOCK_TEST` / `LIVE_CLASS` / `RECORDED_VIDEO` keys.
  final Set<FreeFeature> freeAccessFeatures;

  /// Per-feature usage caps, keyed by the API's own field names.
  ///
  /// Only [maxMockTests] is actually enforceable today — see [FreeFeature].
  final int? maxMockTests;
  final int? maxLiveClasses;

  final String supportMobileNumber;

  /// When the config document itself was created.
  ///
  /// Used as the trial epoch: an account created before the trial feature
  /// existed cannot fairly have its clock started at signup, so those fall back
  /// to a device-local anchor instead. See [AccessControl].
  final DateTime? configCreatedAt;

  /// The signed-in student's trial state, as the backend reports it.
  ///
  /// All four are null when the request had no valid student token (the
  /// pre-login fetch, or a session that has just been cleared) or when talking
  /// to a backend that predates these fields. [hasUserTrialState] is the
  /// single check for "did the server tell us anything about this user".
  final bool? isTrialActive;
  final int? trialDaysLeft;
  final int? mockTestsUsed;
  final int? liveClassesUsed;

  const AppConfig({
    required this.isTrialEnabled,
    required this.freeTrialDays,
    required this.freeAccessFeatures,
    this.maxMockTests,
    this.maxLiveClasses,
    this.supportMobileNumber = '',
    this.configCreatedAt,
    this.isTrialActive,
    this.trialDaysLeft,
    this.mockTestsUsed,
    this.liveClassesUsed,
  });

  /// What the app assumes when `/config` cannot be reached.
  ///
  /// Deliberately permissive: a backend outage (or the development flavor,
  /// which has no `/config` route at all) must never lock a paying user out of
  /// the app. Trial off + everything free = the pre-trial behaviour the app
  /// shipped with.
  static const AppConfig fallback = AppConfig(
    isTrialEnabled: false,
    freeTrialDays: 0,
    freeAccessFeatures: <FreeFeature>{},
  );

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    final limits = data['featureLimits'] as Map<String, dynamic>? ?? const {};

    final features = <FreeFeature>{};
    for (final raw in (data['freeAccessFeatures'] as List<dynamic>? ?? const [])) {
      final feature = FreeFeature.fromLabel(raw?.toString() ?? '');
      if (feature != null) features.add(feature);
    }

    return AppConfig(
      isTrialEnabled: data['isTrialEnabled'] as bool? ?? false,
      freeTrialDays: (data['freeTrialDays'] as num?)?.toInt() ?? 0,
      freeAccessFeatures: features,
      maxMockTests: (limits['maxMockTests'] as num?)?.toInt(),
      maxLiveClasses: (limits['maxLiveClasses'] as num?)?.toInt(),
      supportMobileNumber: data['supportMobileNumber'] as String? ?? '',
      configCreatedAt: DateTime.tryParse(data['createdAt']?.toString() ?? ''),
      isTrialActive: data['isTrialActive'] as bool?,
      trialDaysLeft: (data['trialDaysLeft'] as num?)?.toInt(),
      mockTestsUsed: (data['mockTestsUsed'] as num?)?.toInt(),
      liveClassesUsed: (data['liveClassesUsed'] as num?)?.toInt(),
    );
  }

  /// Whether the backend included the signed-in student's trial state.
  bool get hasUserTrialState => isTrialActive != null;

  /// The cap for [feature], or `null` when the backend sets none (which means
  /// unlimited — "Recorded Videos" is advertised as free but has no limit).
  int? limitFor(FreeFeature feature) => switch (feature) {
        FreeFeature.mockTest => maxMockTests,
        FreeFeature.liveClass => maxLiveClasses,
        FreeFeature.recordedVideo => null,
      };

  /// How much of [feature] the backend says this student has consumed, or
  /// null when it reports nothing for it (no token, old backend, or a feature
  /// it does not meter).
  int? usedFor(FreeFeature feature) => switch (feature) {
        FreeFeature.mockTest => mockTestsUsed,
        FreeFeature.liveClass => liveClassesUsed,
        FreeFeature.recordedVideo => null,
      };

  bool isFree(FreeFeature feature) => freeAccessFeatures.contains(feature);

  /// Whether the backend has actually supplied a support number.
  ///
  /// The field is served as an empty string until an admin fills it in, and
  /// there is deliberately no hardcoded fallback — a number that only lives in
  /// the dashboard cannot drift out of date behind an app-store release. Screens
  /// hide their contact affordances rather than offering a dead one.
  bool get hasSupportNumber => supportMobileNumber.trim().isNotEmpty;

  /// The support number reduced to what a `tel:` or `sms:` URI can dial.
  ///
  /// Admins type numbers however they like — "+880 1640-521788",
  /// "01640-521788" — so punctuation and spacing are stripped for dialling
  /// while [supportMobileNumber] stays as entered for display.
  String get dialableSupportNumber =>
      supportMobileNumber.replaceAll(RegExp(r'[^0-9+]'), '');
}

/// The features `freeAccessFeatures` can name.
///
/// Each carries the backend's enum [key] (`MOCK_TEST`, `LIVE_CLASS`,
/// `RECORDED_VIDEO`), which is what the API now sends.
///
/// NOTE: [liveClass] has no implementation in this app — it is parsed so the
/// config round-trips faithfully, but nothing gates on it yet.
enum FreeFeature {
  mockTest('MOCK_TEST'),
  liveClass('LIVE_CLASS'),
  recordedVideo('RECORDED_VIDEO');

  const FreeFeature(this.key);

  /// The backend's stable identifier for this feature.
  final String key;

  /// Resolves a `freeAccessFeatures` entry.
  ///
  /// Exact [key] matches are the contract. The tolerant fallback — case,
  /// spacing, punctuation and singular/plural insensitive — is kept so a
  /// backend still serving the older display labels ("Mock Tests") keeps
  /// working during the rollout.
  static FreeFeature? fromLabel(String label) {
    for (final feature in values) {
      if (feature.key == label) return feature;
    }

    final key = label.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return switch (key) {
      'mocktest' || 'mocktests' => FreeFeature.mockTest,
      'liveclass' || 'liveclasses' => FreeFeature.liveClass,
      'recordedvideo' ||
      'recordedvideos' ||
      'recordedclass' ||
      'recordedclasses' =>
        FreeFeature.recordedVideo,
      _ => null,
    };
  }
}
