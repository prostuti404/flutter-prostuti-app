import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/question_pattern_model.dart';
import '../repository/question_pattern_repo.dart';

part 'question_pattern_viewmodel.g.dart';

@Riverpod(keepAlive: false)
class QuestionPatternViewmodel extends _$QuestionPatternViewmodel {
  @override
  Future<QuestionPattern?> build() async {
    // Initial state: no data
    return null;
  }

  Future<QuestionPattern?> loadFirstQuestionPattern({
    String? categoryGroup,
    String? categorySubject,
    String? questionType,
  }) async {
    state = const AsyncLoading();

    try {
      final patterns = await ref.read(questionPatternRepoProvider).fetchQuestionPatterns(
        categoryGroup: categoryGroup,
        categorySubject: categorySubject,
        questionType: questionType,
      );

      final first = patterns.isNotEmpty ? patterns.first : null;
      state = AsyncData(first);
      return first;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
