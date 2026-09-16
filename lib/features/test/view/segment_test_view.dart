import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ensure this is imported
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gap/gap.dart';
import 'package:prostuti/core/services/localization_service.dart';
import 'package:prostuti/features/test/view/segment_test_pattern_view.dart';

import '../../../common/widgets/common_widgets/common_widgets.dart';
import '../../../common/widgets/long_button.dart';
import '../../chat/viewmodel/user_category.dart';
import '../../flashcard/viewmodel/flashcard_filter_viewmodel.dart';
import '../viewmodel/question_pattern_viewmodel.dart';

class SegmentTestLandingView extends ConsumerStatefulWidget {
  const SegmentTestLandingView({super.key});

  @override
  ConsumerState<SegmentTestLandingView> createState() =>
      _SegmentTestLandingViewState();
}

class _SegmentTestLandingViewState extends ConsumerState<SegmentTestLandingView>
    with CommonWidgets {
  String? _selectedType;

  // Academic specific
  String? _selectedDivision;

  // Job specific
  String? _selectedJobType;
  String? _selectedJobName;

  // Admission specific
  String? _selectedUniversityType;
  String? _selectedUniversityName;
  String? _selectedUnit;

  // Common
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    await ref.read(categoriesProvider.future);
  }

  void _startSegmentTest() async {
    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select a subject',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    try {
      final pattern = await ref
          .read(questionPatternViewmodelProvider.notifier)
          .loadFirstQuestionPattern(
            categoryType: _selectedType,
            categoryDivision: _selectedDivision,
            categorySubject: _selectedSubject,
          );

      if (pattern == null) {
        Fluttertoast.showToast(msg: 'No question pattern found');
        return;
      }

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SegmentTestPatternView(
                    pattern: pattern,
                  )));
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Widget _buildSecondLevelDropdown() {
    final categoriesAsync = ref.watch(categoriesProvider);

    if (_selectedType == null) return const SizedBox.shrink();

    switch (_selectedType) {
      case 'Academic':
        return _buildFormField(
          label: context.l10n!.division,
          child: categoriesAsync.when(
            data: (categories) {
              final divisions = ref
                  .read(categoriesProvider.notifier)
                  .getUniqueDivisions(categories);
              return _buildDropdown(
                hint: context.l10n!.selectDivision,
                value: _selectedDivision,
                items: divisions,
                onChanged: (newValue) {
                  setState(() {
                    _selectedDivision = newValue;
                    _selectedSubject = null;
                  });
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Failed to load divisions'),
          ),
        );

      case 'Job':
        return _buildFormField(
          label: 'Job Type*',
          child: categoriesAsync.when(
            data: (categories) {
              final jobTypes = ref
                  .read(categoriesProvider.notifier)
                  .getUniqueJobTypes(categories);
              return _buildDropdown(
                hint: 'Select Job Type',
                value: _selectedJobType,
                items: jobTypes,
                onChanged: (newValue) {
                  setState(() {
                    _selectedJobType = newValue;
                    _selectedJobName = null;
                    _selectedSubject = null;
                  });
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Failed to load job types'),
          ),
        );

      case 'Admission':
        return _buildFormField(
          label: 'University Type*',
          child: categoriesAsync.when(
            data: (categories) {
              final universityTypes = ref
                  .read(categoriesProvider.notifier)
                  .getUniqueUniversityTypes(categories);
              return _buildDropdown(
                hint: 'Select University Type',
                value: _selectedUniversityType,
                items: universityTypes,
                onChanged: (newValue) {
                  setState(() {
                    _selectedUniversityType = newValue;
                    _selectedUniversityName = null;
                    _selectedUnit = null;
                    _selectedSubject = null;
                  });
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Failed to load university types'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildThirdLevelDropdown() {
    final categoriesAsync = ref.watch(categoriesProvider);

    if (_selectedType == null) return const SizedBox.shrink();

    switch (_selectedType) {
      case 'Job':
        if (_selectedJobType == null) return const SizedBox.shrink();
        return _buildFormField(
          label: 'Job Name*',
          child: categoriesAsync.when(
            data: (categories) {
              final jobNames = ref
                  .read(categoriesProvider.notifier)
                  .getUniqueJobNames(categories, _selectedJobType);
              return _buildDropdown(
                hint: 'Select Job Name',
                value: _selectedJobName,
                items: jobNames,
                onChanged: (newValue) {
                  setState(() {
                    _selectedJobName = newValue;
                    _selectedSubject = null;
                  });
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Failed to load job names'),
          ),
        );

      case 'Admission':
        if (_selectedUniversityType != 'University')
          return const SizedBox.shrink();
        return _buildFormField(
          label: 'University Name*',
          child: categoriesAsync.when(
            data: (categories) {
              final universityNames = ref
                  .read(categoriesProvider.notifier)
                  .getUniqueUniversityNames(
                      categories, _selectedUniversityType);
              return _buildDropdown(
                hint: 'Select University Name',
                value: _selectedUniversityName,
                items: universityNames,
                onChanged: (newValue) {
                  setState(() {
                    _selectedUniversityName = newValue;
                    _selectedUnit = null;
                    _selectedSubject = null;
                  });
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Failed to load university names'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFourthLevelDropdown() {
    final categoriesAsync = ref.watch(categoriesProvider);

    if (_selectedType != 'Admission' ||
        _selectedUniversityType != 'University' ||
        _selectedUniversityName == null) {
      return const SizedBox.shrink();
    }

    return _buildFormField(
      label: 'Unit*',
      child: categoriesAsync.when(
        data: (categories) {
          final units = ref.read(categoriesProvider.notifier).getUniqueUnits(
              categories, _selectedUniversityType, _selectedUniversityName);
          return _buildDropdown(
            hint: 'Select Unit',
            value: _selectedUnit,
            items: units,
            onChanged: (newValue) {
              setState(() {
                _selectedUnit = newValue;
                _selectedSubject = null;
              });
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('Failed to load units'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final userCategoryAsync = ref.watch(userCategoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: commonAppbar(context.l10n!.segmentTest),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                context.l10n!.segmentTestDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Gap(16),
              // Course field
              userCategoryAsync.when(
                data: (data) {
                  _selectedType = data;
                  return _buildFormField(
                    label: context.l10n!.course,
                    child: categoriesAsync.when(
                      data: (categories) {
                        final types = ref
                            .read(categoriesProvider.notifier)
                            .getUniqueTypes(categories);
                        return _buildDropdown(
                          hint: context.l10n!.selectCourse,
                          value: _selectedType,
                          items: types,
                          onChanged: null,
                        );
                      },
                      loading: () => const Center(child: Text("Loading...")),
                      error: (_, __) => const Text('Failed to load categories'),
                    ),
                  );
                },
                loading: () => const Center(child: Text("Loading...")),
                error: (_, __) => const Text('Failed to load categories'),
              ),

              // Second level dropdown (Division/JobType/UniversityType)
              _buildSecondLevelDropdown(),

              // Third level dropdown (JobName/UniversityName for University type)
              _buildThirdLevelDropdown(),

              // Fourth level dropdown (Unit for University)
              _buildFourthLevelDropdown(),

              // Subject field
              _buildFormField(
                label: context.l10n!.subject,
                child: categoriesAsync.when(
                  data: (categories) {
                    final subjects = _selectedType != null
                        ? ref
                            .read(categoriesProvider.notifier)
                            .getUniqueSubjects(
                              categories,
                              FilterState(
                                selectedType: _selectedType,
                                selectedDivision: _selectedDivision,
                                selectedJobType: _selectedJobType,
                                selectedJobName: _selectedJobName,
                                selectedUniversityType: _selectedUniversityType,
                                selectedUniversityName: _selectedUniversityName,
                                selectedUnit: _selectedUnit,
                              ),
                            )
                        : <String>[];
                    return _buildDropdown(
                      hint: context.l10n!.selectSubject,
                      value: _selectedSubject,
                      items: subjects,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedSubject = newValue;
                        });
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Failed to load subjects'),
                ),
              ),

              LongButton(
                onPressed: _startSegmentTest,
                text: context.l10n!.next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Gap(8),
        child,
        const Gap(16),
      ],
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.onSurface),
        borderRadius: BorderRadius.circular(4),
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            isExpanded: true,
            hint: Text(
              hint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            value: value,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: BorderRadius.circular(8),
            items: items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
