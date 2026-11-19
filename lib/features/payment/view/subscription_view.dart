// lib/features/payment/view/subscription_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gap/gap.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:prostuti/common/widgets/common_widgets/common_widgets.dart';
import 'package:prostuti/core/services/localization_service.dart';
import 'package:prostuti/core/services/nav.dart';
import 'package:prostuti/core/services/size_config.dart';
import 'package:prostuti/features/payment/view/easy_checkout.dart';
import 'package:prostuti/features/payment/viewmodel/check_subscription.dart';
import 'package:prostuti/features/payment/viewmodel/payment_viewmodel.dart';
import 'package:prostuti/features/payment/viewmodel/voucher_viewmodel.dart';
import 'package:prostuti/features/payment/widgets/subscription_card.dart';

import '../../../core/services/debouncer.dart';
import '../model/subscription_plan_model.dart';
import '../viewmodel/selected_index.dart';
import '../viewmodel/subscription_plans_viewmodel.dart';
import '../widgets/subscription_plans_skeleton.dart';
import '../widgets/terms_condition.dart';

final _loadingProvider = StateProvider<bool>((ref) => false);
final _voucherAppliedProvider = StateProvider<bool>((ref) => false);

class SubscriptionView extends ConsumerWidget with CommonWidgets {
  SubscriptionView({super.key});

  /// Display name for a plan, keyed off its length so the labels stay
  /// localised. Anything the backend adds beyond the three known lengths falls
  /// back to its raw `plan` string.
  String _planTitle(BuildContext context, SubscriptionPlan plan) =>
      switch (plan.durationInMonths) {
        12 => context.l10n!.premiumPlanTitle,
        6 => context.l10n!.standardPlanTitle,
        1 => context.l10n!.basicPlanTitle,
        _ => plan.plan,
      };

  String _durationText(BuildContext context, SubscriptionPlan plan) =>
      switch (plan.durationInMonths) {
        12 => context.l10n!.forOneYear,
        6 => context.l10n!.forSixMonths,
        1 => context.l10n!.forOneMonth,
        final months => context.l10n!.forMonths(months),
      };

  @override
  Widget build(BuildContext context, ref) {
    final alreadyActiveSubscriptionMsg =
        context.l10n!.alreadyActiveSubscription;
    final plansAsyncValue = ref.watch(subscriptionPlansNotifierProvider);
    final plans = plansAsyncValue.valueOrNull ?? const <SubscriptionPlan>[];
    // The default selection (index 0) can outrun the plan list while it is
    // still loading, or if the backend serves fewer plans than before.
    final selectedIndex = plans.isEmpty
        ? 0
        : ref.watch(selectedIndexNotifierProvider).clamp(0, plans.length - 1);
    final subscriptionAsyncValue = ref.watch(userSubscribedProvider);
    final _debouncer = Debouncer(milliseconds: 120);
    final isLoading = ref.watch(_loadingProvider);
    final voucherState = ref.watch(voucherNotifierProvider);
    final isVoucherApplied = ref.watch(_voucherAppliedProvider);
    final paymentNotifier = ref.watch(paymentNotifierProvider.notifier);

    // Get current plan and its original price

    final currentPlan = plans.isEmpty ? null : plans[selectedIndex];
    final originalPrice = (currentPlan?.price ?? 0).toDouble();

    // Calculate final price with voucher if applied
    final finalPrice = voucherState.hasValue && voucherState.value != null
        ? ref
            .read(voucherNotifierProvider.notifier)
            .getFinalPrice(originalPrice)
        : originalPrice;

    return Scaffold(
        appBar: commonAppbar(context.l10n!.subscription),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  plansAsyncValue.when(
                    data: (plans) {
                      if (plans.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              context.l10n!.noSubscriptionPlans,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: plans.length,
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(selectedIndexNotifierProvider.notifier)
                                  .updateIndex(index);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: SubscriptionCard(
                                planTitle: _planTitle(context, plan),
                                price: "৳ ${plan.priceLabel}",
                                durationText: _durationText(context, plan),
                                isSelected: index == selectedIndex,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const SubscriptionPlansSkeleton(),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Text(
                            context.l10n!.errorOccurred,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Gap(12),
                          TextButton(
                            onPressed: () => ref
                                .invalidate(subscriptionPlansNotifierProvider),
                            child: Text(context.l10n!.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(24),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: subscriptionAsyncValue.when(
          data: (isSubscribed) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: SizeConfig.h(150),
              child: Column(
                children: [
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          // Nothing to buy until the plans have loaded.
                          onPressed: isLoading || currentPlan == null
                              ? null
                              : () {
                                  _debouncer.run(
                                    action: () async {
                                      final paymentUrl = await paymentNotifier
                                          .initiateSubscription(
                                        currentPlan.plan,
                                        applyVoucher: isVoucherApplied,
                                      );

                                      if (paymentUrl != null &&
                                          paymentUrl.isNotEmpty) {
                                        // Valid URL received, navigate to checkout
                                        Nav().pushReplacement(
                                            EasyCheckout(url: paymentUrl));
                                      } else {
                                        // No URL received, check for error or already subscribed
                                        final paymentState =
                                            ref.read(paymentNotifierProvider);
                                        if (paymentState.hasError) {
                                          Fluttertoast.showToast(
                                            msg: paymentState.error.toString(),
                                          );
                                        } else {
                                          // Could be already subscribed
                                          Fluttertoast.showToast(
                                            msg: alreadyActiveSubscriptionMsg,
                                          );
                                        }
                                      }
                                    },
                                    loadingController:
                                        ref.read(_loadingProvider.notifier),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              backgroundColor: const Color(0xff2970FF),
                              fixedSize:
                                  Size(SizeConfig.w(356), SizeConfig.h(54))),
                          child: Text(
                            context.l10n!.payNow,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800),
                          ),
                        ),
                  const Gap(16),
                  ElevatedButton(
                    onPressed: () {
                      showMaterialModalBottomSheet(
                        enableDrag: true,
                        expand: false,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        bounce: true,
                        context: context,
                        builder: (context) => const TermsCondition(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(
                                color: Color(0xff155EEF), width: 3),
                            borderRadius: BorderRadius.circular(4)),
                        backgroundColor: const Color(0xffD1E0FF),
                        fixedSize: Size(SizeConfig.w(356), SizeConfig.h(54))),
                    child: Text(
                      context.l10n!.termsAndConditions,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: const Color(0xff2970FF),
                          fontWeight: FontWeight.w900),
                    ),
                  )
                ],
              ),
            );
          },
          error: (error, stackTrace) {
            return Center(
              child: Text('$error'),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ));
  }
}
