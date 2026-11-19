import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prostuti/core/services/dio_service.dart';

import '../model/question_pattern_model.dart';

part 'question_pattern_repo.g.dart';

@riverpod
QuestionPatternRepo questionPatternRepo(QuestionPatternRepoRef ref) {
  final dioService = ref.watch(dioServiceProvider);
  return QuestionPatternRepo(dioService);
}

class QuestionPatternRepo {
  final DioService _dioService;

  QuestionPatternRepo(this._dioService);

  /// Fetches question patterns. [categoryGroup] and [questionType] ("MCQ" |
  /// "Written") are server-side filters (API doc section 7.1). When
  /// [categorySubject] is given, patterns whose categories cover that subject
  /// are returned first.
  Future<List<QuestionPattern>> fetchQuestionPatterns({
    String? categoryGroup,
    String? categorySubject,
    String? questionType,
    String? searchTerm,
  }) async {
    const String endpoint = '/question-pattern/all-question-pattern';

    final Map<String, String> params = {
      if (categoryGroup != null && categoryGroup.isNotEmpty)
        'categoryGroup': categoryGroup,
      if (questionType != null && questionType.isNotEmpty)
        'questionType': questionType,
      if (searchTerm != null && searchTerm.isNotEmpty)
        'searchTerm': searchTerm,
    };

    final response = await _dioService.getRequest(endpoint, queryParameters: params);

    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> rawData = _extractList(response.data['data']);
      final patterns =
          rawData.map((json) => QuestionPattern.fromJson(json)).toList();

      if (categorySubject != null && categorySubject.isNotEmpty) {
        bool matches(QuestionPattern p) =>
            (p.categoryId ?? []).any((c) => c.subject == categorySubject) ||
            (p.mainSubjects ?? []).any((m) => m.subject == categorySubject);
        patterns.sort((a, b) =>
            (matches(b) ? 1 : 0).compareTo(matches(a) ? 1 : 0));
      }
      return patterns;
    } else {
      throw Exception(response.data['message'] ?? 'Failed to load question patterns');
    }
  }

  /// The pattern list is nested as `data.data` on the live API; accept a flat
  /// `data` array too.
  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}
