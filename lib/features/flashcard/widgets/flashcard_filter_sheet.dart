import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:prostuti/core/services/localization_service.dart';

import '../viewmodel/flashcard_filter_viewmodel.dart';
import '../viewmodel/flashcard_viewmodel.dart';

/// Group -> Subject -> Lesson cascading filter for the explore flashcards list.
class FlashcardFilterSheet extends ConsumerStatefulWidget {
  const FlashcardFilterSheet({super.key});

  @override
  FlashcardFilterSheetState createState() => FlashcardFilterSheetState();
}

class FlashcardFilterSheetState extends ConsumerState<FlashcardFilterSheet> {
  bool _isGroupExpanded = true;
  bool _isSubjectExpanded = false;
  bool _isLessonExpanded = false;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final filterState = ref.watch(flashcardFilterProvider);
    final notifier = ref.read(categoriesProvider.notifier);
    final filterNotifier = ref.read(flashcardFilterProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n!.filter,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Gap(16),
          Flexible(
            child: SingleChildScrollView(
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('${context.l10n!.error}: $error')),
                data: (categories) {
                  final groups = notifier.getUniqueGroups(categories);
                  final subjects = notifier.getUniqueSubjects(
                      categories, filterState.selectedGroup);
                  final lessons = notifier.getUniqueLessons(
                      categories,
                      filterState.selectedGroup,
                      filterState.selectedSubject);

                  return Column(
                    children: [
                      _buildFilterSection(
                        title: context.l10n!.group,
                        isExpanded: _isGroupExpanded,
                        onToggle: () => setState(
                            () => _isGroupExpanded = !_isGroupExpanded),
                        content: groups.isEmpty
                            ? Center(
                                child: Text(context.l10n!.noGroupsAvailable))
                            : _buildOptionsList(
                                items: groups,
                                selectedValue: filterState.selectedGroup,
                                onSelected: (value) {
                                  filterNotifier.setGroup(value);
                                  setState(() {
                                    _isGroupExpanded = false;
                                    _isSubjectExpanded = true;
                                    _isLessonExpanded = false;
                                  });
                                },
                              ),
                      ),
                      const Gap(16),
                      if (filterState.selectedGroup != null) ...[
                        _buildFilterSection(
                          title: context.l10n!.subject,
                          isExpanded: _isSubjectExpanded,
                          onToggle: () => setState(
                              () => _isSubjectExpanded = !_isSubjectExpanded),
                          content: subjects.isEmpty
                              ? Center(
                                  child: Text(
                                      context.l10n!.noSubjectsAvailable))
                              : _buildOptionsList(
                                  items: subjects,
                                  selectedValue: filterState.selectedSubject,
                                  onSelected: (value) {
                                    filterNotifier.setSubject(value);
                                    setState(() {
                                      _isSubjectExpanded = false;
                                      _isLessonExpanded = true;
                                    });
                                  },
                                ),
                        ),
                        const Gap(16),
                      ],
                      if (filterState.selectedSubject != null)
                        _buildFilterSection(
                          title: context.l10n!.lesson,
                          isExpanded: _isLessonExpanded,
                          onToggle: () => setState(
                              () => _isLessonExpanded = !_isLessonExpanded),
                          content: lessons.isEmpty
                              ? Center(
                                  child:
                                      Text(context.l10n!.noLessonsAvailable))
                              : _buildOptionsList(
                                  items: lessons,
                                  selectedValue: filterState.selectedLesson,
                                  onSelected: filterNotifier.setLesson,
                                ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const Gap(24),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    ref.read(flashcardFilterProvider.notifier).applyFilters();
                    ref.invalidate(exploreFlashcardsProvider);
                    ref.invalidate(userFlashcardsProvider);
                    Navigator.pop(context);
                  },
                  child: Text(
                    context.l10n!.applyFilter,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
              if (filterState.isFilterActive) ...[
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: Color(0xff2970FF)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      ref.read(flashcardFilterProvider.notifier).resetFilters();
                      ref.invalidate(exploreFlashcardsProvider);
                      ref.invalidate(userFlashcardsProvider);
                      Navigator.pop(context);
                    },
                    child: Text(
                      context.l10n!.resetFilter,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: const Color(0xff2970FF),
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.onSecondary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildOptionsList({
    required List<String> items,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    return Column(
      children: items.map((item) {
        final isSelected = item == selectedValue;

        return InkWell(
          onTap: () => onSelected(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        )
                      : null,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w400,
                          color: isSelected
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
