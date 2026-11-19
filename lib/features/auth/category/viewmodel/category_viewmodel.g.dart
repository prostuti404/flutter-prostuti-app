// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$registrationCategoriesHash() =>
    r'09b941a463b9e630fcc979c70bef4d4b01b4a20f';

/// The categories offered by the registration picker.
///
/// Never fails: if `/auth/registration-categories` cannot be reached the
/// picker shows [RegistrationCategory.fallback] (main categories only) so a
/// backend hiccup does not strand someone on the last step of signing up.
///
/// Copied from [registrationCategories].
@ProviderFor(registrationCategories)
final registrationCategoriesProvider =
    AutoDisposeFutureProvider<List<RegistrationCategory>>.internal(
  registrationCategories,
  name: r'registrationCategoriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$registrationCategoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RegistrationCategoriesRef
    = AutoDisposeFutureProviderRef<List<RegistrationCategory>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
