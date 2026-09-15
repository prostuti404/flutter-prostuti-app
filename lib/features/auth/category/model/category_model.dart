import 'category_constant.dart';

/// One main category and its sub-categories, from
/// `GET /auth/registration-categories`.
///
/// Both strings are wire values (`"Academic"`, `"Science"`, ...) that go back
/// to the backend verbatim on registration — only the labels are localised.
class RegistrationCategory {
  final String mainCategory;
  final List<String> subCategories;

  const RegistrationCategory({
    required this.mainCategory,
    this.subCategories = const [],
  });

  factory RegistrationCategory.fromJson(Map<String, dynamic> json) {
    return RegistrationCategory(
      mainCategory: json['mainCategory']?.toString() ?? '',
      subCategories: (json['subCategories'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mainCategory': mainCategory,
        'subCategories': subCategories,
      };

  /// Whether picking this category also requires picking a sub-category.
  /// "Job" ships with an empty list, so it completes in one step.
  bool get hasSubCategories => subCategories.isNotEmpty;

  /// What the picker shows when the endpoint cannot be reached: the three
  /// main categories the backend has always accepted, with no sub-step, so a
  /// transient failure never blocks someone from finishing registration.
  static const List<RegistrationCategory> fallback = [
    RegistrationCategory(mainCategory: MainCategory.ACADEMIC),
    RegistrationCategory(mainCategory: MainCategory.ADMISSION),
    RegistrationCategory(mainCategory: MainCategory.JOB),
  ];
}
