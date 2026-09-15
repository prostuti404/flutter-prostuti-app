import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/category_model.dart';
import '../repository/category_repo.dart';

part 'category_viewmodel.g.dart';

/// The categories offered by the registration picker.
///
/// Never fails: if `/auth/registration-categories` cannot be reached the
/// picker shows [RegistrationCategory.fallback] (main categories only) so a
/// backend hiccup does not strand someone on the last step of signing up.
@riverpod
Future<List<RegistrationCategory>> registrationCategories(
    RegistrationCategoriesRef ref) async {
  final result =
      await ref.read(categoryRepoProvider).getRegistrationCategories();

  return result.fold(
    (_) => RegistrationCategory.fallback,
    (categories) =>
        categories.isEmpty ? RegistrationCategory.fallback : categories,
  );
}
