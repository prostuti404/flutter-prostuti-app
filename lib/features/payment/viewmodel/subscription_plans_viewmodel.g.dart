// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_plans_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionPlansNotifierHash() =>
    r'0d6eaa6638bba60bfade9b49ff05be37674e1de0';

/// The subscription plans on offer, from `GET /subscription/plans`.
///
/// Plans are ordered longest-first so the top card (selected by default) is the
/// annual plan, matching how the screen has always been laid out.
///
/// Copied from [SubscriptionPlansNotifier].
@ProviderFor(SubscriptionPlansNotifier)
final subscriptionPlansNotifierProvider = AutoDisposeAsyncNotifierProvider<
    SubscriptionPlansNotifier, List<SubscriptionPlan>>.internal(
  SubscriptionPlansNotifier.new,
  name: r'subscriptionPlansNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionPlansNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SubscriptionPlansNotifier
    = AutoDisposeAsyncNotifier<List<SubscriptionPlan>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
