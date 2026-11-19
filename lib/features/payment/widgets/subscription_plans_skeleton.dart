import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'subscription_card.dart';

/// Placeholder cards shown while `GET /subscription/plans` is in flight.
class SubscriptionPlansSkeleton extends StatelessWidget {
  final int itemCount;

  const SubscriptionPlansSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SubscriptionCard(
            planTitle: 'Premium Plan',
            price: '৳ 6000',
            durationText: 'for 1 year',
          ),
        ),
      ),
    );
  }
}
