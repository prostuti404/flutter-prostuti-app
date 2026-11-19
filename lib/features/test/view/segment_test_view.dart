import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ensure this is imported
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gap/gap.dart';
import 'package:prostuti/core/services/localization_service.dart';
import 'package:prostuti/features/test/view/segment_test_pattern_view.dart';

import '../../../common/widgets/common_widgets/common_widgets.dart';
import '../../../common/widgets/long_button.dart';
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
  String? _selectedGroup;
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
            categoryGroup: _selectedGroup,
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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

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
              // Group field (Science / Commerce / Arts)
              _buildFormField(
                label: context.l10n!.group,
                child: categoriesAsync.when(
                  data: (categories) {
                    final groups = ref
                        .read(categoriesProvider.notifier)
                        .getUniqueGroups(categories);
                    return _buildDropdown(
                      hint: context.l10n!.group,
                      value: _selectedGroup,
                      items: groups,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGroup = newValue;
                          _selectedSubject = null;
                        });
                      },
                    );
                  },
                  loading: () => const Center(child: Text("Loading...")),
                  error: (_, __) => const Text('Failed to load categories'),
                ),
              ),

              // Subject field
              _buildFormField(
                label: context.l10n!.subject,
                child: categoriesAsync.when(
                  data: (categories) {
                    final subjects = ref
                        .read(categoriesProvider.notifier)
                        .getUniqueSubjects(categories, _selectedGroup);
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
