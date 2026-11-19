// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$exploreFlashcardsHash() => r'a8b71b111c197d076dc3dd527b5bbcb09e389486';

/// See also [ExploreFlashcards].
@ProviderFor(ExploreFlashcards)
final exploreFlashcardsProvider = AutoDisposeAsyncNotifierProvider<
    ExploreFlashcards, List<Flashcard>>.internal(
  ExploreFlashcards.new,
  name: r'exploreFlashcardsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exploreFlashcardsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ExploreFlashcards = AutoDisposeAsyncNotifier<List<Flashcard>>;
String _$userFlashcardsHash() => r'a1f0e3a3a24fb241c2266ccb38b6d3652aa21f0b';

/// See also [UserFlashcards].
@ProviderFor(UserFlashcards)
final userFlashcardsProvider =
    AutoDisposeAsyncNotifierProvider<UserFlashcards, List<Flashcard>>.internal(
  UserFlashcards.new,
  name: r'userFlashcardsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userFlashcardsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserFlashcards = AutoDisposeAsyncNotifier<List<Flashcard>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
