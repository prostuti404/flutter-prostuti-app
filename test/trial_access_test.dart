import 'package:flutter_test/flutter_test.dart';
import 'package:prostuti/features/config/model/app_config.dart';
import 'package:prostuti/features/payment/viewmodel/access_control.dart';

/// The body `GET /api/v1/config` returned before the per-user fields landed:
/// display labels in `freeAccessFeatures` and nothing about the caller.
///
/// Kept so the app keeps working against a deployment that has not picked up
/// the newer shape yet — the parser must accept both.
const Map<String, dynamic> _stagingConfigResponse = {
  "success": true,
  "message": "App configuration retrieved successfully",
  "data": {
    "supportMobileNumber": "",
    "_id": "6a920975f7277badf8d3d4d6",
    "isTrialEnabled": true,
    "freeTrialDays": 7,
    "freeAccessFeatures": ["Mock Tests", "Live Classes", "Recorded Videos"],
    "createdAt": "2026-08-28T22:19:33.618Z",
    "updatedAt": "2026-08-28T22:19:46.940Z",
    "__v": 0,
    "featureLimits": {"maxMockTests": 56, "maxLiveClasses": 56}
  }
};

/// The current contract, captured verbatim from a signed-in request: stable
/// enum keys in `freeAccessFeatures`, plus the caller's own trial state.
///
/// Pinned here so a change to the contract — a renamed key, a dropped counter
/// — fails a test instead of silently changing who gets gated. Re-capture it
/// if the backend deliberately changes shape.
const Map<String, dynamic> _signedInConfigResponse = {
  "success": true,
  "message": "App configuration retrieved successfully",
  "data": {
    "supportMobileNumber": "",
    "_id": "6a920975f7277badf8d3d4d6",
    "isTrialEnabled": true,
    "freeTrialDays": 7,
    "freeAccessFeatures": ["MOCK_TEST", "LIVE_CLASS", "RECORDED_VIDEO"],
    "createdAt": "2026-08-28T22:19:33.618Z",
    "updatedAt": "2026-08-28T22:19:46.940Z",
    "__v": 0,
    "featureLimits": {"maxMockTests": 56, "maxLiveClasses": 56},
    "isTrialActive": true,
    "trialDaysLeft": 7,
    "mockTestsUsed": 0,
    "liveClassesUsed": 0
  }
};

TrialStatus _trial(
  AppConfig config, {
  Map<FreeFeature, int> usage = const {},
  Duration remaining = const Duration(days: 3),
}) =>
    TrialStatus(
      tier: AccessTier.trial,
      config: config,
      trialEndsAt: DateTime.now().add(remaining),
      usage: usage,
    );

void main() {
  group('AppConfig.fromJson against the live staging payload', () {
    final config = AppConfig.fromJson(_stagingConfigResponse);

    test('reads the trial switch and window', () {
      expect(config.isTrialEnabled, isTrue);
      expect(config.freeTrialDays, 7);
    });

    test('normalises the display labels onto stable keys', () {
      expect(
        config.freeAccessFeatures,
        {FreeFeature.mockTest, FreeFeature.liveClass, FreeFeature.recordedVideo},
      );
    });

    test('reads featureLimits', () {
      expect(config.maxMockTests, 56);
      expect(config.maxLiveClasses, 56);
    });

    test('treats a free feature with no limit as uncapped', () {
      // The backend lists "Recorded Videos" as free but sets no cap for it.
      expect(config.isFree(FreeFeature.recordedVideo), isTrue);
      expect(config.limitFor(FreeFeature.recordedVideo), isNull);
    });

    test('captures the config creation date used as the trial epoch', () {
      expect(config.configCreatedAt, DateTime.parse('2026-08-28T22:19:33.618Z'));
    });
  });

  group('AppConfig.fromJson against the signed-in payload', () {
    final config = AppConfig.fromJson(_signedInConfigResponse);

    test('resolves the enum keys onto FreeFeature', () {
      expect(
        config.freeAccessFeatures,
        {FreeFeature.mockTest, FreeFeature.liveClass, FreeFeature.recordedVideo},
      );
    });

    test('reads the per-user trial state', () {
      expect(config.hasUserTrialState, isTrue);
      expect(config.isTrialActive, isTrue);
      expect(config.trialDaysLeft, 7);
      expect(config.mockTestsUsed, 0);
      expect(config.liveClassesUsed, 0);
    });

    test('maps the usage counters onto the features they meter', () {
      expect(config.usedFor(FreeFeature.mockTest), 0);
      expect(config.usedFor(FreeFeature.liveClass), 0);
      // Recorded videos are free and unmetered — no counter exists for them.
      expect(config.usedFor(FreeFeature.recordedVideo), isNull);
    });

    test('the global part is unchanged from the older shape', () {
      final legacy = AppConfig.fromJson(_stagingConfigResponse);
      expect(config.isTrialEnabled, legacy.isTrialEnabled);
      expect(config.freeTrialDays, legacy.freeTrialDays);
      expect(config.freeAccessFeatures, legacy.freeAccessFeatures);
      expect(config.maxMockTests, legacy.maxMockTests);
      expect(config.maxLiveClasses, legacy.maxLiveClasses);
    });
  });

  group('per-user trial state is absent', () {
    test('on the older payload, so the device-local fallback stays in play', () {
      final config = AppConfig.fromJson(_stagingConfigResponse);
      expect(config.hasUserTrialState, isFalse);
      expect(config.trialDaysLeft, isNull);
      expect(config.usedFor(FreeFeature.mockTest), isNull);
    });

    test('on the fallback config', () {
      expect(AppConfig.fallback.hasUserTrialState, isFalse);
    });
  });

  group('FreeFeature.fromLabel', () {
    test('matches the backend enum keys exactly', () {
      expect(FreeFeature.fromLabel('MOCK_TEST'), FreeFeature.mockTest);
      expect(FreeFeature.fromLabel('LIVE_CLASS'), FreeFeature.liveClass);
      expect(FreeFeature.fromLabel('RECORDED_VIDEO'), FreeFeature.recordedVideo);
      for (final feature in FreeFeature.values) {
        expect(FreeFeature.fromLabel(feature.key), feature, reason: feature.key);
      }
    });

    test('is tolerant of case, spacing and singular/plural', () {
      for (final label in ['Mock Tests', 'mock test', 'MOCKTESTS', ' Mock-Tests ']) {
        expect(FreeFeature.fromLabel(label), FreeFeature.mockTest, reason: label);
      }
      expect(FreeFeature.fromLabel('Recorded Classes'), FreeFeature.recordedVideo);
    });

    test('drops labels it does not recognise rather than guessing', () {
      expect(FreeFeature.fromLabel('Podcasts'), isNull);
      expect(FreeFeature.fromLabel(''), isNull);
    });
  });

  group('malformed or partial config', () {
    test('missing fields degrade to a closed-but-harmless config', () {
      final config = AppConfig.fromJson({'data': <String, dynamic>{}});
      expect(config.isTrialEnabled, isFalse);
      expect(config.freeTrialDays, 0);
      expect(config.freeAccessFeatures, isEmpty);
      expect(config.maxMockTests, isNull);
    });

    test('an unparseable body does not throw', () {
      expect(() => AppConfig.fromJson(const {}), returnsNormally);
    });

    test('the fallback grants access, so an outage never locks users out', () {
      const status =
          TrialStatus(tier: AccessTier.unrestricted, config: AppConfig.fallback);
      expect(status.accessTo(FreeFeature.mockTest).allowed, isTrue);
      expect(status.shouldPromptSubscription, isFalse);
    });
  });

  group('supportMobileNumber', () {
    test('the live payload currently ships it empty', () {
      // Staging serves "" until an admin fills it in. There is deliberately no
      // hardcoded fallback, so the contact buttons stay hidden until then.
      final config = AppConfig.fromJson(_stagingConfigResponse);
      expect(config.supportMobileNumber, '');
      expect(config.hasSupportNumber, isFalse);
    });

    test('a missing field is treated as empty, never null', () {
      expect(AppConfig.fromJson(const {}).supportMobileNumber, '');
      expect(AppConfig.fallback.supportMobileNumber, '');
      expect(AppConfig.fallback.hasSupportNumber, isFalse);
    });

    test('whitespace alone does not count as a number', () {
      final config = AppConfig.fromJson({
        'data': {'supportMobileNumber': '   '}
      });
      expect(config.hasSupportNumber, isFalse);
    });

    test('a configured number is reported as present', () {
      final config = AppConfig.fromJson({
        'data': {'supportMobileNumber': '01640521788'}
      });
      expect(config.hasSupportNumber, isTrue);
      expect(config.dialableSupportNumber, '01640521788');
    });

    test('however an admin formats it, it reduces to something dialable', () {
      const entries = {
        '+880 1640-521788': '+8801640521788',
        '01640-521788': '01640521788',
        '(017) 1234 5678': '01712345678',
      };
      entries.forEach((typed, dialable) {
        final config = AppConfig.fromJson({
          'data': {'supportMobileNumber': typed}
        });
        expect(config.dialableSupportNumber, dialable, reason: typed);
        // The raw entry survives for display.
        expect(config.supportMobileNumber, typed);
      });
    });
  });

  group('access decisions', () {
    final config = AppConfig.fromJson(_stagingConfigResponse);

    test('a subscriber is never gated', () {
      final status = TrialStatus(tier: AccessTier.subscribed, config: config);
      for (final feature in FreeFeature.values) {
        expect(status.accessTo(feature).allowed, isTrue, reason: feature.name);
      }
      expect(status.shouldPromptSubscription, isFalse);
    });

    test('a trial user under the cap is allowed, and sees what is left', () {
      final access = _trial(config, usage: {FreeFeature.mockTest: 10})
          .accessTo(FreeFeature.mockTest);

      expect(access.allowed, isTrue);
      expect(access.reason, AccessReason.withinTrial);
      expect(access.used, 10);
      expect(access.limit, 56);
      expect(access.remaining, 46);
    });

    test('a trial user at the cap is blocked', () {
      final access = _trial(config, usage: {FreeFeature.mockTest: 56})
          .accessTo(FreeFeature.mockTest);

      expect(access.allowed, isFalse);
      expect(access.reason, AccessReason.limitReached);
      expect(access.remaining, 0);
    });

    test('remaining never goes negative past the cap', () {
      final access = _trial(config, usage: {FreeFeature.mockTest: 99})
          .accessTo(FreeFeature.mockTest);
      expect(access.remaining, 0);
      expect(access.allowed, isFalse);
    });

    test('an uncapped free feature stays open however much it is used', () {
      final access = _trial(config, usage: {FreeFeature.recordedVideo: 9999})
          .accessTo(FreeFeature.recordedVideo);
      expect(access.allowed, isTrue);
      expect(access.reason, AccessReason.withinTrial);
    });

    test('a feature absent from freeAccessFeatures is closed during a trial', () {
      const bare = AppConfig(
        isTrialEnabled: true,
        freeTrialDays: 7,
        freeAccessFeatures: {FreeFeature.recordedVideo},
      );
      final access = _trial(bare).accessTo(FreeFeature.mockTest);
      expect(access.allowed, isFalse);
      expect(access.reason, AccessReason.notIncluded);
    });

    test('an expired trial closes everything and prompts to subscribe', () {
      final status = TrialStatus(
        tier: AccessTier.expired,
        config: config,
        trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      for (final feature in FreeFeature.values) {
        final access = status.accessTo(feature);
        expect(access.allowed, isFalse, reason: feature.name);
        expect(access.reason, AccessReason.trialExpired);
      }
      expect(status.shouldPromptSubscription, isTrue);
      expect(status.daysRemaining, 0);
    });
  });

  group('daysRemaining', () {
    final config = AppConfig.fromJson(_stagingConfigResponse);

    test('rounds a part-day up, so the last day still reads as 1', () {
      expect(_trial(config, remaining: const Duration(hours: 5)).daysRemaining, 1);
      expect(
          _trial(config, remaining: const Duration(hours: 30)).daysRemaining, 2);
    });

    test('is zero once the window has closed', () {
      final status = TrialStatus(
        tier: AccessTier.trial,
        config: config,
        trialEndsAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(status.daysRemaining, 0);
    });

    test('prefers the number the backend reported over date arithmetic', () {
      final status = TrialStatus(
        tier: AccessTier.trial,
        config: config,
        // The date alone would say 2; the server says 5, and the server wins.
        trialEndsAt: DateTime.now().add(const Duration(hours: 30)),
        reportedDaysLeft: 5,
      );
      expect(status.daysRemaining, 5);
    });

    test('a reported negative never surfaces as a negative day count', () {
      final status = TrialStatus(
        tier: AccessTier.expired,
        config: config,
        reportedDaysLeft: -3,
      );
      expect(status.daysRemaining, 0);
    });
  });

  group('server-reported usage drives the gate', () {
    final config = AppConfig.fromJson(_signedInConfigResponse);

    test('a fresh trial user is allowed with the full allowance', () {
      final status = TrialStatus(
        tier: AccessTier.trial,
        config: config,
        reportedDaysLeft: config.trialDaysLeft,
        usage: {
          for (final f in FreeFeature.values) f: config.usedFor(f) ?? 0,
        },
      );
      final access = status.accessTo(FreeFeature.mockTest);
      expect(access.allowed, isTrue);
      expect(access.used, 0);
      expect(access.remaining, 56);
      expect(status.daysRemaining, 7);
    });

    test('the backend saying the cap is spent blocks the feature', () {
      final spent = AppConfig.fromJson({
        ...(_signedInConfigResponse),
        'data': {
          ...(_signedInConfigResponse['data'] as Map<String, dynamic>),
          'mockTestsUsed': 56,
        },
      });
      final status = TrialStatus(
        tier: AccessTier.trial,
        config: spent,
        usage: {FreeFeature.mockTest: spent.usedFor(FreeFeature.mockTest)!},
      );
      final access = status.accessTo(FreeFeature.mockTest);
      expect(access.allowed, isFalse);
      expect(access.reason, AccessReason.limitReached);
    });
  });
}
