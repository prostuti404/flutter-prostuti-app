import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/subscription_plan_model.dart';
import '../repository/payment_repo.dart';

part 'subscription_plans_viewmodel.g.dart';

/// The subscription plans on offer, from `GET /subscription/plans`.
///
/// Plans are ordered longest-first so the top card (selected by default) is the
/// annual plan, matching how the screen has always been laid out.
@riverpod
class SubscriptionPlansNotifier extends _$SubscriptionPlansNotifier {
  @override
  Future<List<SubscriptionPlan>> build() async {
    final result = await ref.read(paymentRepoProvider).getSubscriptionPlans();

    return result.fold(
      (error) => throw Exception(error.message),
      (plans) {
        final sorted = [...plans]
          ..sort((a, b) => b.durationInMonths.compareTo(a.durationInMonths));
        return sorted;
      },
    );
  }
}
