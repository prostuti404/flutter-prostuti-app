import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:prostuti/common/widgets/long_button.dart';
import 'package:prostuti/core/services/localization_service.dart';
import 'package:prostuti/features/test/view/written_mock_quiz_screen.dart';
import 'package:prostuti/features/test/viewmodel/quizer_test_viewmodel.dart';
import 'package:prostuti/features/test/viewmodel/quizer_written_test_viewmodel.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../common/widgets/common_widgets/common_widgets.dart';
import '../viewmodel/subject_selector_viewmodel.dart';
import '../widgets/question_standard_selector.dart';
import '../widgets/subject_dropdown.dart';
import '../widgets/test_type_selector_button.dart';
import 'mcq_mock_quiz_view.dart';

class QuizerTestLandingView extends ConsumerStatefulWidget {
  const QuizerTestLandingView({super.key});

  @override
  ConsumerState<QuizerTestLandingView> createState() =>
      _QuizerTestLandingViewState();
}

class _QuizerTestLandingViewState extends ConsumerState<QuizerTestLandingView>
    with CommonWidgets {
  final TextEditingController questionCountController = TextEditingController();
  final TextEditingController hourController = TextEditingController();
  final TextEditingController minuteController = TextEditingController();
  final TextEditingController secondController = TextEditingController();
  bool isNegativeMarking = false;
  String selectedQuestionType = "MCQ";
  String selectedStandard = QuestionStandard.engineering;
  List<SelectedSubjectAndChapter> selectedSubjects = [];
  List<String> questionFilters = [];

  @override
  void initState() {
    super.initState();
    // Add one subject selector by default. An empty subject is the
    // "nothing picked yet" sentinel; the dropdown shows a localized
    // placeholder label for it instead of storing translated text.
    selectedSubjects.add(SelectedSubjectAndChapter(subject: ""));
  }

  // Helper method to convert hours, minutes, seconds to total minutes
  int _convertToTotalMinutes() {
    final hours = int.tryParse(hourController.text.trim()) ?? 0;
    final minutes = int.tryParse(minuteController.text.trim()) ?? 0;
    final seconds = int.tryParse(secondController.text.trim()) ?? 0;

    // Convert everything to minutes
    return (hours * 60) +
        minutes +
        (seconds > 0 ? 1 : 0); // Round up if seconds > 0
  }

  Widget _buildTimeInputField(TextEditingController controller, String label) {
    return Expanded(
      child: Column(
        children: [
          Center(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "00",
                hintStyle: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const Gap(8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _startMCQQuizerTest() async {
    final int questionCount = int.tryParse(questionCountController.text) ?? 0;
    final int time = _convertToTotalMinutes();

    // Filter out placeholder subjects. The list is now of the correct type.
    final validSubjects = selectedSubjects
        .where((s) => s.subject.isNotEmpty)
        .map((s) => s.toJson()) // Convert to JSON
        .toList();

    if (validSubjects.isEmpty) {
      _showValidationError(context.l10n!.selectAtLeastOneSubject);
      return;
    }

    final validQuestionFilters = questionFilters
        .where((filters) => filters != "প্রশ্নের ধরণ সিলেক্ট করুন")
        .toList();

    if (validQuestionFilters.isEmpty) {
      _showValidationError(context.l10n!.selectAtLeastOneQuestionType);
      return;
    }

    if (questionCount <= 0) {
      _showValidationError(context.l10n!.enterValidQuestionCount);
      return;
    }
    if (time <= 0) {
      _showValidationError(context.l10n!.enterValidTime);
      return;
    }

    try {
      final response =
          await ref.read(quizerTestViewmodelProvider.notifier).createMCQQuizer(
                questionType: selectedQuestionType,
                subjects: validSubjects,
                questionFilters: validQuestionFilters,
                questionCount: questionCount,
                isNegativeMarking: isNegativeMarking,
                time: time,
              );

      if (response != null && response.data != null) {
        if (response.success!) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MCQMockQuizScreen(mockQuiz: response),
            ),
          );
        } else {
          _showValidationError(response.message!);
        }
      }
    } catch (e) {
      _showValidationError(e.toString());
    }
  }

  void _startWrittenQuizerTest() async {
    final int questionCount = int.tryParse(questionCountController.text) ?? 0;
    final int time = _convertToTotalMinutes();

    // Filter out placeholder subjects. The list is now of the correct type.
    final validSubjects = selectedSubjects
        .where((s) => s.subject.isNotEmpty)
        .map((s) => s.toJson()) // Convert to JSON
        .toList();

    if (validSubjects.isEmpty) {
      _showValidationError(context.l10n!.selectAtLeastOneSubject);
      return;
    }

    final validQuestionFilters = questionFilters
        .where((filters) => filters != "প্রশ্নের ধরণ সিলেক্ট করুন")
        .toList();

    if (validQuestionFilters.isEmpty) {
      _showValidationError(context.l10n!.selectAtLeastOneQuestionType);
      return;
    }

    if (questionCount <= 0) {
      _showValidationError(context.l10n!.enterValidQuestionCount);
      return;
    }
    if (time <= 0) {
      _showValidationError(context.l10n!.enterValidTime);
      return;
    }

    try {
      final response = await ref
          .read(quizerWrittenTestViewmodelProvider.notifier)
          .createWrittenQuizer(
            questionType: selectedQuestionType,
            subjects: validSubjects,
            questionFilters: validQuestionFilters,
            questionCount: questionCount,
            isNegativeMarking: isNegativeMarking,
            time: time,
          );
      if (response != null && response.data != null) {
        if (response.success!) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WrittenMockQuizScreen(mockQuiz: response),
            ),
          );
        } else {
          _showValidationError(response.message!);
        }
      }
    } catch (e) {
      _showValidationError(e.toString());
    }
  }

  void _showValidationError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n!.errorTitle,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            // Close the dialog
            child: Text(context.l10n!.ok,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizerTestViewmodelProvider);
    final subjectState = ref.watch(subjectViewmodelProvider(selectedStandard));
    final isSubjectLoading = subjectState.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: commonAppbar(context.l10n!.quizer),
      body: Skeletonizer(
        enabled: isSubjectLoading,
        child: state.when(
          data: (data) => _buildContent(context),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text("Error: ${err.toString()}")),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n!.selectTestType,
                style: Theme.of(context).textTheme.bodyMedium),
            const Gap(10),
            TestTypeSelector(
              selectedType: selectedQuestionType,
              onTypeChanged: (value) =>
                  setState(() => selectedQuestionType = value),
            ),
            const Gap(10),
            Text(context.l10n!.questionStandard,
                style: Theme.of(context).textTheme.bodyMedium),
            const Gap(10),
            QuestionStandardSelector(
              selectedStandard: selectedStandard,
              onStandardChanged: (value) => setState(() {
                selectedStandard = value;
                selectedSubjects = [SelectedSubjectAndChapter(subject: "")];
              }),
            ),
            const Gap(10),
            Text('${context.l10n!.subject}*',
                style: Theme.of(context).textTheme.bodyMedium),
            const Gap(10),
            ...selectedSubjects.asMap().entries.map((entry) {
              final index = entry.key;
              final subject = entry.value;
              final selectedExcludingCurrent = selectedSubjects
                  .asMap()
                  .entries
                  .where((e) => e.key != index)
                  .map((e) => e.value.subject)
                  .toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final subjectListAsync = ref.watch(
                              subjectViewmodelProvider(selectedStandard));

                          return subjectListAsync.when(
                            data: (subjects) {
                              final availableSubjects = subjects;
                              final dropdownSubjects = [
                                "",
                                ...availableSubjects
                              ];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Subject Dropdown
                                  DropdownButtonFormField<String>(
                                    value: selectedSubjects[index]
                                                .subject
                                                .isEmpty ||
                                            !dropdownSubjects.contains(
                                                selectedSubjects[index].subject)
                                        ? ""
                                        : selectedSubjects[index].subject,
                                    items: dropdownSubjects
                                        .map((subject) =>
                                            DropdownMenuItem<String>(
                                              value: subject,
                                              child: Text(
                                                subject.isEmpty
                                                    ? context.l10n!.selectSubject
                                                    : subject,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        setState(() {
                                          selectedSubjects[index].subject =
                                              value;
                                          selectedSubjects[index].chapter =
                                              "All"; // reset chapter on subject change
                                        });
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 10),

                                  // Chapter Dropdown (shown only if subject selected)
                                  if (selectedSubjects[index]
                                      .subject
                                      .isNotEmpty)
                                    ref
                                        .watch(chapterViewmodelProvider(
                                            selectedSubjects[index].subject))
                                        .when(
                                          data: (chapters) {
                                            final List<String> chapterOptions =
                                                ["All", ...chapters]
                                                    .toSet()
                                                    .toList();
                                            final otherSelectedChapters =
                                                selectedSubjects
                                                    .asMap()
                                                    .entries
                                                    .where((entry) =>
                                                        entry.key != index &&
                                                        entry.value.subject ==
                                                            selectedSubjects[
                                                                    index]
                                                                .subject)
                                                    .map((entry) =>
                                                        entry.value.chapter)
                                                    .toList();
                                            return DropdownButtonFormField<
                                                String>(
                                              value: chapterOptions.contains(
                                                      selectedSubjects[index]
                                                          .chapter)
                                                  ? selectedSubjects[index]
                                                      .chapter
                                                  : chapterOptions.first,
                                              items:
                                                  chapterOptions.map((chapter) {
                                                final isSelectedElsewhere =
                                                    otherSelectedChapters
                                                            .contains(
                                                                chapter) &&
                                                        chapter != 'All';
                                                return DropdownMenuItem<String>(
                                                  value: chapter,
                                                  enabled: !isSelectedElsewhere,
                                                  child: Text(
                                                    chapter,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          color:
                                                              isSelectedElsewhere
                                                                  ? Colors.grey
                                                                  : null,
                                                        ),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  if (otherSelectedChapters
                                                          .contains(value) &&
                                                      value != 'All') {
                                                    _showValidationError(
                                                        "This chapter has already been selected for this subject.");
                                                  } else {
                                                    setState(() =>
                                                        selectedSubjects[index]
                                                            .chapter = value);
                                                  }
                                                }
                                              },
                                            );
                                          },
                                          loading: () => const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                          error: (err, _) =>
                                              Text("Error loading chapters"),
                                        ),
                                ],
                              );
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (err, _) => Text("Error loading subjects"),
                          );
                        },
                      ),
                    ),
                    if (selectedSubjects.length > 1)
                      IconButton(
                        onPressed: () =>
                            setState(() => selectedSubjects.removeAt(index)),
                        icon: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              );
            }),
            const Gap(10),
            TextButton.icon(
              onPressed: () => setState(
                () => selectedSubjects.add(
                  SelectedSubjectAndChapter(subject: ""),
                ),
              ),
              label: Text(context.l10n!.addAnotherSubject,
                  style: Theme.of(context).textTheme.bodyMedium),
              icon: Icon(CupertinoIcons.plus_app,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const Gap(10),
            Text(context.l10n!.questionTypeFilterLabel,
                style: Theme.of(context).textTheme.bodyMedium),
            const Gap(10),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip("Favorite Questions"),
                _buildFilterChip("Unanswered Questions"),
                _buildFilterChip("Wrong Questions"),
              ],
            ),
            const Gap(10),
            Text(context.l10n!.questionCount,
                style: Theme.of(context).textTheme.bodyMedium),
            const Gap(10),
            TextField(
              controller: questionCountController,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(hintText: context.l10n!.selectQuestionCount),
            ),
            const Gap(10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n!.negativeMarking,
                  style: Theme.of(context).textTheme.bodyMedium),
              value: isNegativeMarking,
              activeColor: Theme.of(context).colorScheme.onSecondary,
              inactiveThumbColor: Theme.of(context).colorScheme.secondary,
              onChanged: (value) => setState(() => isNegativeMarking = value),
            ),
            const Gap(10),
            Text(context.l10n!.testDuration,
                style: Theme.of(context).textTheme.bodyMedium),
            const Gap(16),
            Row(
              children: [
                _buildTimeInputField(hourController, context.l10n!.hours),
                const Gap(16),
                _buildTimeInputField(minuteController, context.l10n!.minutes),
                const Gap(16),
                _buildTimeInputField(secondController, context.l10n!.seconds),
              ],
            ),
            const Gap(20),
            LongButton(
              onPressed: selectedQuestionType == "MCQ"
                  ? _startMCQQuizerTest
                  : _startWrittenQuizerTest,
              text: context.l10n!.startTest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = questionFilters.contains(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            questionFilters.add(label);
          } else {
            if (questionFilters.length > 1) {
              questionFilters.remove(label);
            }
          }
        });
      },
      checkmarkColor: selected
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.secondary,
      selectedColor: Theme.of(context).colorScheme.onSecondary,
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
