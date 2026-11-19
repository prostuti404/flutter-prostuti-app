import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/category_model.dart';
import '../repository/flashcard_repo.dart';

part 'flashcard_filter_viewmodel.g.dart';

/// Cascading Group -> Subject -> Lesson filter (API doc section 2.3).
class FilterState {
  final String? selectedGroup;
  final String? selectedSubject;
  final String? selectedLesson;
  final bool isFilterActive;

  FilterState({
    this.selectedGroup,
    this.selectedSubject,
    this.selectedLesson,
    this.isFilterActive = false,
  });

  FilterState copyWith({
    String? selectedGroup,
    String? selectedSubject,
    String? selectedLesson,
    bool? isFilterActive,
  }) {
    return FilterState(
      selectedGroup: selectedGroup ?? this.selectedGroup,
      selectedSubject: selectedSubject ?? this.selectedSubject,
      selectedLesson: selectedLesson ?? this.selectedLesson,
      isFilterActive: isFilterActive ?? this.isFilterActive,
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (selectedGroup != null && selectedGroup!.isNotEmpty) {
      params['categoryGroup'] = selectedGroup!;
    }
    if (selectedSubject != null && selectedSubject!.isNotEmpty) {
      params['categorySubject'] = selectedSubject!;
    }
    if (selectedLesson != null && selectedLesson!.isNotEmpty) {
      params['categoryLesson'] = selectedLesson!;
    }
    return params;
  }
}

@Riverpod(keepAlive: true)
class FlashcardFilter extends _$FlashcardFilter {
  @override
  FilterState build() {
    return FilterState();
  }

  // Changing a level clears every level below it.
  void setGroup(String? group) {
    state = FilterState(
      selectedGroup: group,
      isFilterActive: state.isFilterActive,
    );
  }

  void setSubject(String? subject) {
    state = FilterState(
      selectedGroup: state.selectedGroup,
      selectedSubject: subject,
      isFilterActive: state.isFilterActive,
    );
  }

  void setLesson(String? lesson) {
    state = FilterState(
      selectedGroup: state.selectedGroup,
      selectedSubject: state.selectedSubject,
      selectedLesson: lesson,
      isFilterActive: state.isFilterActive,
    );
  }

  void applyFilters() {
    state = state.copyWith(isFilterActive: true);
  }

  void resetFilters() {
    state = FilterState();
  }
}

/// Categories that actually have content (`onlyCreated=true&limit=0`).
@Riverpod(keepAlive: true)
class Categories extends _$Categories {
  @override
  Future<List<Category>> build() async {
    return await _fetchCategories();
  }

  Future<List<Category>> _fetchCategories() async {
    final response = await ref.read(flashcardRepoProvider).getCategories();

    return response.fold(
      (l) {
        throw Exception(l.message);
      },
      (categoryList) {
        return categoryList.data ?? [];
      },
    );
  }

  List<String> _unique(Iterable<String?> values) {
    final seen = <String>{};
    for (final v in values) {
      if (v != null && v.isNotEmpty) seen.add(v);
    }
    return seen.toList();
  }

  List<String> getUniqueGroups(List<Category> categories) {
    return _unique(categories.map((c) => c.group));
  }

  List<String> getUniqueSubjects(List<Category> categories, String? group) {
    if (group == null || group.isEmpty) return [];
    return _unique(
      categories.where((c) => c.group == group).map((c) => c.subject),
    );
  }

  List<String> getUniqueLessons(
    List<Category> categories,
    String? group,
    String? subject,
  ) {
    if (group == null || group.isEmpty || subject == null || subject.isEmpty) {
      return [];
    }
    return _unique(
      categories
          .where((c) => c.group == group && c.subject == subject)
          .map((c) => c.lesson),
    );
  }
}
