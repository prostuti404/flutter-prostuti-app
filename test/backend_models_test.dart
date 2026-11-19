import 'package:flutter_test/flutter_test.dart';
import 'package:prostuti/features/auth/category/model/category_model.dart';
import 'package:prostuti/features/payment/model/subscription_plan_model.dart';

// Parsed against the payloads the staging backend actually serves, so a shape
// change on the server shows up here before it shows up on a device.

void main() {
  group('SubscriptionPlan', () {
    // GET /subscription/plans
    const payload = {
      "success": true,
      "message": "Subscription plans retrieved successfully",
      "data": [
        {"plan": "1 month", "durationInMonths": 1, "price": 500},
        {"plan": "6 months", "durationInMonths": 6, "price": 3000},
        {"plan": "1 year", "durationInMonths": 12, "price": 6000},
      ],
    };

    test('parses every plan with its wire name intact', () {
      final plans = (payload['data'] as List)
          .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(plans.map((p) => p.plan), ['1 month', '6 months', '1 year']);
      expect(plans.map((p) => p.durationInMonths), [1, 6, 12]);
      expect(plans.map((p) => p.price), [500, 3000, 6000]);
    });

    test('priceLabel drops a trailing .0 but keeps real decimals', () {
      expect(
        const SubscriptionPlan(plan: 'x', durationInMonths: 1, price: 500)
            .priceLabel,
        '500',
      );
      expect(
        const SubscriptionPlan(plan: 'x', durationInMonths: 1, price: 500.0)
            .priceLabel,
        '500',
      );
      expect(
        const SubscriptionPlan(plan: 'x', durationInMonths: 1, price: 499.5)
            .priceLabel,
        '499.5',
      );
    });

    test('tolerates missing fields rather than throwing', () {
      final plan = SubscriptionPlan.fromJson(const {});
      expect(plan.plan, '');
      expect(plan.durationInMonths, 0);
      expect(plan.price, 0);
    });
  });

  group('RegistrationCategory', () {
    // GET /auth/registration-categories
    const payload = {
      "success": true,
      "message": "Registration categories retrieved successfully",
      "data": [
        {
          "mainCategory": "Academic",
          "subCategories": ["Science", "Commerce", "Arts"],
        },
        {
          "mainCategory": "Admission",
          "subCategories": ["Engineering", "Medical", "University"],
        },
        {"mainCategory": "Job", "subCategories": []},
      ],
    };

    test('parses main categories with their sub-categories', () {
      final categories = (payload['data'] as List)
          .map((e) => RegistrationCategory.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(categories.map((c) => c.mainCategory),
          ['Academic', 'Admission', 'Job']);
      expect(categories[0].subCategories, ['Science', 'Commerce', 'Arts']);
      expect(categories[1].subCategories,
          ['Engineering', 'Medical', 'University']);
      expect(categories[2].subCategories, isEmpty);
    });

    test('only categories with sub-categories need a second step', () {
      final categories = (payload['data'] as List)
          .map((e) => RegistrationCategory.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(categories.map((c) => c.hasSubCategories), [true, true, false]);
    });

    test('a missing subCategories key means no sub-step', () {
      final category =
          RegistrationCategory.fromJson(const {"mainCategory": "Job"});
      expect(category.hasSubCategories, isFalse);
    });

    test('fallback matches the three categories the backend always took', () {
      expect(RegistrationCategory.fallback.map((c) => c.mainCategory),
          ['Academic', 'Admission', 'Job']);
      expect(RegistrationCategory.fallback.every((c) => !c.hasSubCategories),
          isTrue);
    });
  });
}
