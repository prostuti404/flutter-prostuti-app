import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gap/gap.dart';
import 'package:prostuti/common/widgets/common_widgets/common_widgets.dart';
import 'package:prostuti/core/services/localization_service.dart';
import 'package:prostuti/core/services/nav.dart';
import 'package:prostuti/core/services/size_config.dart';

import '../model/category_model.dart';
import '../model/create_flash_card.dart';
import '../viewmodel/create_flashcard_viewmodel.dart';
import '../viewmodel/flashcard_filter_viewmodel.dart';
import '../viewmodel/flashcard_settings_viewmodel.dart';
import '../viewmodel/flashcard_viewmodel.dart';
import '../widgets/category_picker.dart';
import '../widgets/visibilty_picker.dart';

class CreateFlashcardView extends ConsumerStatefulWidget {
  const CreateFlashcardView({super.key});

  @override
  CreateFlashcardViewState createState() => CreateFlashcardViewState();
}

class CreateFlashcardViewState extends ConsumerState<CreateFlashcardView>
    with CommonWidgets {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String _categoryId = ""; // We'll initialize this from SharedPreferences
  String _visibility = "EVERYONE";
  final List<FlashcardItemFormField> _flashcardItems = [];

  // Add new fields to track selected category details for display
  String? _selectedCategoryGroup;
  String? _selectedCategorySubject;
  String? _selectedCategoryLesson;

  @override
  void initState() {
    super.initState();
    // Add the first flashcard item by default
    _addFlashcardItem();
    // Load saved settings
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final settings = await ref.read(flashcardSettingsNotifierProvider.future);
    setState(() {
      if (settings.categoryId != null && settings.categoryId!.isNotEmpty) {
        _categoryId = settings.categoryId!;
      }
      if (settings.visibility != null && settings.visibility!.isNotEmpty) {
        _visibility = settings.visibility!;
      }
      _selectedCategoryGroup = settings.categoryGroup;
      _selectedCategorySubject = settings.categorySubject;
      _selectedCategoryLesson = settings.categoryLesson;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var item in _flashcardItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addFlashcardItem() {
    setState(() {
      _flashcardItems.add(FlashcardItemFormField());
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check if category is selected
      if (_categoryId.isEmpty) {
        Fluttertoast.showToast(msg: context.l10n!.noSelectedCategory);
        _openSettingsModal();
        return;
      }

      // Create the request object
      final request = CreateFlashcardRequest(
        title: _titleController.text.trim(),
        visibility: _visibility,
        categoryId: _categoryId,
        items: _flashcardItems
            .map((item) => FlashcardItemRequest(
                  term: item.termController.text.trim(),
                  answer: item.answerController.text.trim(),
                ))
            .toList(),
      );

      // Submit the request
      final success = await ref
          .read(createFlashcardNotifierProvider.notifier)
          .createFlashcard(request);

      if (success) {
        ref.invalidate(exploreFlashcardsProvider);
        ref.invalidate(userFlashcardsProvider);
        Navigator.pop(context, true);
        Fluttertoast.showToast(msg: context.l10n!.cardCreatedSuccessfully);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final createFlashcardState = ref.watch(createFlashcardNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.createFlashcard),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Nav().pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _openSettingsModal,
              child: SvgPicture.asset(
                'assets/icons/settings.svg',
                colorFilter: const ColorFilter.linearToSrgbGamma(),
                fit: BoxFit.cover,
              ),
            ),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title section
            Text(
              context.l10n!.title,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Gap(8),
            // Input field with dashed border
            Container(
              decoration: DottedDecoration(
                color: const Color(0xFF2970FF),
                borderRadius: BorderRadius.circular(8),
                strokeWidth: 1.5,
                gap: 5,
              ),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: context.l10n!.titleHint,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const Gap(24),

            // Category indicator
            if (_selectedCategorySubject != null &&
                _selectedCategorySubject!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.category, size: 16),
                    const Gap(8),
                    Expanded(child: _buildCategorySubtitle()),
                  ],
                ),
              ),
              const Gap(16),
            ],

            // Flashcard items
            for (int i = 0; i < _flashcardItems.length; i++) ...[
              // Term field
              Text(
                context.l10n!.term,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Gap(8),
              TextField(
                controller: _flashcardItems[i].termController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF2970FF), width: 1.5),
                  ),
                ),
              ),
              const Gap(16),

              // Answer field
              Text(
                context.l10n!.description,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Gap(8),
              TextField(
                controller: _flashcardItems[i].answerController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF2970FF), width: 1.5),
                  ),
                ),
              ),

              const Gap(24),
            ],

            // Add another flashcard item button
            InkWell(
              onTap: _addFlashcardItem,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF2970FF), width: 1.5),
                    ),
                    child: Icon(Icons.add,
                        color: Theme.of(context).colorScheme.onSecondary,
                        size: 10),
                  ),
                  const Gap(10),
                  Text(
                    context.l10n!.addCard,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                ],
              ),
            ),

            const Gap(32),

            // Create button
            ElevatedButton(
              onPressed: createFlashcardState.isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2970FF),
                disabledBackgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                minimumSize: Size(SizeConfig.w(356), SizeConfig.h(48)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: createFlashcardState.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      context.l10n!.create,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Store current visibility in modal's state to update UI when changed
            String localVisibility = _visibility;

            return Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8),
                    child: Container(
                      height: 60,
                      padding: EdgeInsets.only(right: SizeConfig.w(100)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          Text(
                            context.l10n!.setOptions,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category Selector Card
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                width: 2,
                                color: Colors.grey,
                              ),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ListTile(
                              title: Text(context.l10n!.category),
                              subtitle: _buildCategorySubtitle(),
                              trailing: ElevatedButton(
                                onPressed: () => _showCategoryPicker(
                                  context,
                                  setModalState,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2970FF),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(context.l10n!.select),
                              ),
                            ),
                          ),

                          // Visibility Card - now with a better UI
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                width: 2,
                                color: Colors.grey,
                              ),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ListTile(
                              title: Text(context.l10n!.visibleBy),
                              subtitle: Text(localVisibility == "EVERYONE"
                                  ? context.l10n!.everyone
                                  : context.l10n!.onlyMe),
                              leading: Icon(
                                localVisibility == "EVERYONE"
                                    ? Icons.public
                                    : Icons.lock,
                                color: Theme.of(context).unselectedWidgetColor,
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _showVisibilityPicker(
                                    context, setModalState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2970FF),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(context.l10n!.select),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Pass setModalState to update the parent modal when visibility changes
  void _showVisibilityPicker(BuildContext context, StateSetter setModalState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: VisibilityPicker(
            initialVisibility: _visibility,
            onVisibilitySelected: (visibility) {
              // Update the state in both the view and the modal
              setState(() {
                _visibility = visibility;
              });
              setModalState(() {
                // This updates the UI in the settings modal
              });
            },
            onClose: () => Navigator.pop(context),
          ),
        );
      },
    );
  }

// Fixed category subtitle builder
  Widget _buildCategorySubtitle() {
    if (_categoryId.isEmpty ||
        (_selectedCategorySubject == null ||
            _selectedCategorySubject!.isEmpty)) {
      return Text(context.l10n!.noSelectedCategory);
    }

    final parts = <String>[];
    if (_selectedCategoryGroup != null && _selectedCategoryGroup!.isNotEmpty) {
      parts.add(_selectedCategoryGroup!);
    }
    if (_selectedCategorySubject != null &&
        _selectedCategorySubject!.isNotEmpty) {
      parts.add(_selectedCategorySubject!);
    }
    if (_selectedCategoryLesson != null &&
        _selectedCategoryLesson!.isNotEmpty) {
      parts.add(_selectedCategoryLesson!);
    }

    return Text(parts.join(' > '));
  }

  // Helper method to build the category subtitle text

  // Method to show the category picker
  // Updated method to correctly pass setModalState and update the UI
  void _showCategoryPicker(BuildContext context, StateSetter setModalState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: CategoryPicker(
            onCategorySelected: (categoryId) {
              // Update the displayed category info
              ref.read(categoriesProvider.future).then((categories) {
                final selectedCategory = categories.firstWhere(
                  (c) => c.sId == categoryId,
                  orElse: () => Category(),
                );

                setState(() {
                  _categoryId = categoryId;
                  _selectedCategoryGroup = selectedCategory.group;
                  _selectedCategorySubject = selectedCategory.subject;
                  _selectedCategoryLesson = selectedCategory.lesson;
                });

                // Important: Update the modal UI with the new selection
                setModalState(() {});
              });

              Navigator.pop(context); // Close the category picker
            },
            onClose: () => Navigator.pop(context),
          ),
        );
      },
    );
  }
}

// Helper class to manage form controllers for flashcard items
class FlashcardItemFormField {
  final termController = TextEditingController();
  final answerController = TextEditingController();

  void dispose() {
    termController.dispose();
    answerController.dispose();
  }
}

// Custom class for drawing dotted borders
class DottedDecoration extends Decoration {
  final Color color;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final double gap;

  const DottedDecoration({
    required this.color,
    required this.borderRadius,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _DottedDecoration(
      color: color,
      borderRadius: borderRadius,
      strokeWidth: strokeWidth,
      gap: gap,
    );
  }
}

class _DottedDecoration extends BoxPainter {
  final Color color;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final double gap;

  _DottedDecoration({
    required this.color,
    required this.borderRadius,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    final Rect rect = offset & configuration.size!;
    final RRect rrect = borderRadius.toRRect(rect);

    // Draw the dotted border
    final dashPath = _dashPath(
      Path()..addRRect(rrect),
      dashArray: CircularIntervalList<double>([strokeWidth, gap]),
    );

    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(
    Path source, {
    required CircularIntervalList<double> dashArray,
  }) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final double len = dashArray.next;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }
}

// Helper class for dash pattern
class CircularIntervalList<T> {
  final List<T> _values;
  int _index = 0;

  CircularIntervalList(this._values);

  T get next {
    if (_index >= _values.length) {
      _index = 0;
    }
    return _values[_index++];
  }
}
