/// One entry from `GET /subscription/plans`.
///
/// The `plan` string doubles as the identifier the backend expects back as
/// `requestedPlan` on `POST /payment/subscription/init` ("1 month",
/// "6 months", "1 year"), so it is sent through untouched and never localised.
class SubscriptionPlan {
  final String plan;
  final int durationInMonths;
  final num price;

  const SubscriptionPlan({
    required this.plan,
    required this.durationInMonths,
    required this.price,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      plan: json['plan']?.toString() ?? '',
      durationInMonths: (json['durationInMonths'] as num?)?.toInt() ?? 0,
      price: json['price'] as num? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'plan': plan,
        'durationInMonths': durationInMonths,
        'price': price,
      };

  /// Price without a trailing `.0` when the backend sends a whole number.
  String get priceLabel =>
      price % 1 == 0 ? price.toInt().toString() : price.toString();
}
