import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'flashcard_settings_viewmodel.g.dart';

// Keys for SharedPreferences
const String kSelectedCategoryId = 'selected_category_id';
const String kSelectedVisibility = 'selected_visibility';
const String kSelectedCategoryGroup = 'selected_category_group';
const String kSelectedCategoryLesson = 'selected_category_lesson';
const String kSelectedCategorySubject = 'selected_category_subject';

class FlashcardSettings {
  final String? categoryId;
  final String? visibility;
  final String? categoryGroup;
  final String? categoryLesson;
  final String? categorySubject;

  FlashcardSettings({
    this.categoryId,
    this.visibility = 'EVERYONE',
    this.categoryGroup,
    this.categoryLesson,
    this.categorySubject,
  });

  FlashcardSettings copyWith({
    String? categoryId,
    String? visibility,
    String? categoryGroup,
    String? categoryLesson,
    String? categorySubject,
  }) {
    return FlashcardSettings(
      categoryId: categoryId ?? this.categoryId,
      visibility: visibility ?? this.visibility,
      categoryGroup: categoryGroup ?? this.categoryGroup,
      categoryLesson: categoryLesson ?? this.categoryLesson,
      categorySubject: categorySubject ?? this.categorySubject,
    );
  }

  // Save settings to SharedPreferences
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (categoryId != null) {
      await prefs.setString(kSelectedCategoryId, categoryId!);
    }

    if (visibility != null) {
      await prefs.setString(kSelectedVisibility, visibility!);
    }

    if (categoryGroup != null) {
      await prefs.setString(kSelectedCategoryGroup, categoryGroup!);
    }

    if (categoryLesson != null) {
      await prefs.setString(kSelectedCategoryLesson, categoryLesson!);
    }

    if (categorySubject != null) {
      await prefs.setString(kSelectedCategorySubject, categorySubject!);
    }
  }

  // Load settings from SharedPreferences
  static Future<FlashcardSettings> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    return FlashcardSettings(
      categoryId: prefs.getString(kSelectedCategoryId),
      visibility: prefs.getString(kSelectedVisibility) ?? 'EVERYONE',
      categoryGroup: prefs.getString(kSelectedCategoryGroup),
      categoryLesson: prefs.getString(kSelectedCategoryLesson),
      categorySubject: prefs.getString(kSelectedCategorySubject),
    );
  }
}

@Riverpod(keepAlive: true)
class FlashcardSettingsNotifier extends _$FlashcardSettingsNotifier {
  @override
  Future<FlashcardSettings> build() async {
    return FlashcardSettings.loadFromPrefs();
  }

  Future<void> setCategoryId(String categoryId) async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(categoryId: categoryId);
    await newSettings.saveToPrefs();
    state = AsyncValue.data(newSettings);
  }

  Future<void> setVisibility(String visibility) async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(visibility: visibility);
    await newSettings.saveToPrefs();
    state = AsyncValue.data(newSettings);
  }

  Future<void> setCategoryDetails({
    required String? categoryId,
    required String? categoryGroup,
    required String? categoryLesson,
    required String? categorySubject,
  }) async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(
      categoryId: categoryId,
      categoryGroup: categoryGroup,
      categoryLesson: categoryLesson,
      categorySubject: categorySubject,
    );
    await newSettings.saveToPrefs();
    state = AsyncValue.data(newSettings);
  }
}
