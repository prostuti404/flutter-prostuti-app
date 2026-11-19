import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/flashcard_model.dart';
import '../repository/flashcard_repo.dart';
import 'flashcard_filter_viewmodel.dart';

part 'flashcard_viewmodel.g.dart';

@Riverpod(keepAlive: false)
class ExploreFlashcards extends _$ExploreFlashcards {
  List<Flashcard> _allFlashcards = [];
  List<Flashcard> _filteredFlashcards = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  String _currentSearchQuery = '';

  List<Flashcard> get filteredFlashcards => _filteredFlashcards;

  bool get hasMoreData => _hasMoreData;

  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<Flashcard>> build() async {
    final filterState = ref.watch(flashcardFilterProvider);

    _allFlashcards = await _fetchFlashcards(
      page: 1,
      categoryGroup:
          filterState.isFilterActive ? filterState.selectedGroup : null,
      categorySubject:
          filterState.isFilterActive ? filterState.selectedSubject : null,
      categoryLesson:
          filterState.isFilterActive ? filterState.selectedLesson : null,
    );
    _filteredFlashcards = _allFlashcards;
    _currentPage = 1;
    _hasMoreData = true;
    return _allFlashcards;
  }

  Future<List<Flashcard>> _fetchFlashcards({
    required int page,
    int limit = 10,
    String? categoryGroup,
    String? categorySubject,
    String? categoryLesson,
  }) async {
    final response = await ref.read(flashcardRepoProvider).getAllFlashcards(
          page: page,
          limit: limit,
          visibility: "EVERYONE",
          categoryGroup: categoryGroup,
          categorySubject: categorySubject,
          categoryLesson: categoryLesson,
        );

    return response.fold(
      (l) {
        throw Exception(l.message);
      },
      (flashcardList) {
        final newFlashcards = flashcardList.data?.data ?? [];

        // Check if we have more data
        final totalCount = flashcardList.data?.meta?.count ?? 0;
        final currentCount = (_currentPage - 1) * limit + newFlashcards.length;
        _hasMoreData = currentCount < totalCount;

        return newFlashcards;
      },
    );
  }

  Future<void> loadMoreData() async {
    if (!_hasMoreData || _isLoadingMore) return;

    try {
      _isLoadingMore = true;
      final filterState = ref.read(flashcardFilterProvider);

      final nextPage = _currentPage + 1;
      final moreFlashcards = await _fetchFlashcards(
        page: nextPage,
        categoryGroup:
            filterState.isFilterActive ? filterState.selectedGroup : null,
        categorySubject:
            filterState.isFilterActive ? filterState.selectedSubject : null,
        categoryLesson:
            filterState.isFilterActive ? filterState.selectedLesson : null,
      );

      if (moreFlashcards.isNotEmpty) {
        _currentPage = nextPage;
        _allFlashcards = [..._allFlashcards, ...moreFlashcards];

        // If we're filtering, apply the filter to the new cards as well
        if (_currentSearchQuery.isNotEmpty) {
          filterFlashcards(_currentSearchQuery);
        } else {
          _filteredFlashcards = _allFlashcards;
          state = AsyncValue.data(_filteredFlashcards);
        }
      } else {
        _hasMoreData = false;
      }

      _isLoadingMore = false;
    } catch (e) {
      _isLoadingMore = false;
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void filterFlashcards(String query) {
    _currentSearchQuery = query;

    if (query.isEmpty) {
      _filteredFlashcards = _allFlashcards;
    } else {
      // Efficient search algorithm using case-insensitive comparison
      _filteredFlashcards = _allFlashcards
          .where((flashcard) =>
              flashcard.title?.toLowerCase().contains(query.toLowerCase()) ??
              false)
          .toList();
    }

    // Notify listeners of the updated state
    state = AsyncValue.data(_filteredFlashcards);
  }
}

@Riverpod(keepAlive: false)
class UserFlashcards extends _$UserFlashcards {
  List<Flashcard> _userFlashcards = [];
  List<Flashcard> _filteredUserFlashcards = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  String _currentSearchQuery = '';

  List<Flashcard> get filteredFlashcards => _filteredUserFlashcards;

  bool get hasMoreData => _hasMoreData;

  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<Flashcard>> build() async {
    _userFlashcards = await _fetchFlashcards(page: 1);
    _filteredUserFlashcards = _userFlashcards;
    _currentPage = 1;
    _hasMoreData = true;
    return _userFlashcards;
  }

  Future<List<Flashcard>> _fetchFlashcards(
      {required int page, int limit = 10}) async {
    final response = await ref
        .read(flashcardRepoProvider)
        .getAllFlashcards(page: page, limit: limit, visibility: "ONLY_ME");

    return response.fold(
      (l) {
        throw Exception(l.message);
      },
      (flashcardList) {
        final newFlashcards = flashcardList.data?.data ?? [];

        // Check if we have more data (based on meta data or by checking if we received fewer items than requested)
        final totalCount = flashcardList.data?.meta?.count ?? 0;
        final currentCount = (_currentPage - 1) * limit + newFlashcards.length;
        _hasMoreData = currentCount < totalCount;

        return newFlashcards;
      },
    );
  }

  Future<void> loadMoreData() async {
    if (!_hasMoreData || _isLoadingMore) return;

    try {
      _isLoadingMore = true;

      final nextPage = _currentPage + 1;
      final moreFlashcards = await _fetchFlashcards(page: nextPage);

      if (moreFlashcards.isNotEmpty) {
        _currentPage = nextPage;
        _userFlashcards = [..._userFlashcards, ...moreFlashcards];

        // If we're filtering, apply the filter to the new cards as well
        if (_currentSearchQuery.isNotEmpty) {
          filterFlashcards(_currentSearchQuery);
        } else {
          _filteredUserFlashcards = _userFlashcards;
          state = AsyncValue.data(_filteredUserFlashcards);
        }
      } else {
        _hasMoreData = false;
      }

      _isLoadingMore = false;
    } catch (e) {
      _isLoadingMore = false;
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void filterFlashcards(String query) {
    _currentSearchQuery = query;

    if (query.isEmpty) {
      _filteredUserFlashcards = _userFlashcards;
    } else {
      _filteredUserFlashcards = _userFlashcards
          .where((flashcard) =>
              flashcard.title?.toLowerCase().contains(query.toLowerCase()) ??
              false)
          .toList();
    }

    // Notify listeners of the updated state
    state = AsyncValue.data(_filteredUserFlashcards);
  }
}
