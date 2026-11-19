// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_filter_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$flashcardFilterHash() => r'de8f462d0163c73722b045f6a3a56ba76d87f525';

/// See also [FlashcardFilter].
@ProviderFor(FlashcardFilter)
final flashcardFilterProvider =
    NotifierProvider<FlashcardFilter, FilterState>.internal(
  FlashcardFilter.new,
  name: r'flashcardFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$flashcardFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FlashcardFilter = Notifier<FilterState>;
String _$categoriesHash() => r'370b4945069c6ef595521525e39754c6de5e7e3b';

/// Categories that actually have content (`onlyCreated=true&limit=0`).
///
/// Copied from [Categories].
@ProviderFor(Categories)
final categoriesProvider =
    AsyncNotifierProvider<Categories, List<Category>>.internal(
  Categories.new,
  name: r'categoriesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$categoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Categories = AsyncNotifier<List<Category>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
