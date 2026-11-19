import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:prostuti/core/services/localization_service.dart';

import '../model/category_model.dart';
import '../viewmodel/flashcard_filter_viewmodel.dart';
import '../viewmodel/flashcard_settings_viewmodel.dart';

/// Picks the single category (Group -> Subject -> Lesson) a flashcard deck is
/// linked to via `categoryId`.
class CategoryPicker extends ConsumerStatefulWidget {
  final Function(String) onCategorySelected;
  final VoidCallback onClose;

  const CategoryPicker({
    super.key,
    required this.onCategorySelected,
    required this.onClose,
  });

  @override
  ConsumerState<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<CategoryPicker>
    with SingleTickerProviderStateMixin {
  String? _selectedGroup;
  String? _selectedSubject;
  String? _selectedLesson;
  String? _selectedCategoryId;

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _initializeFromSettings();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeFromSettings() async {
    final settings = await ref.read(flashcardSettingsNotifierProvider.future);
    if (!mounted) return;
    setState(() {
      _selectedGroup = settings.categoryGroup;
      _selectedSubject = settings.categorySubject;
      _selectedLesson = settings.categoryLesson;
      _selectedCategoryId = settings.categoryId;
    });
  }

  void _selectCategory(Category category) {
    setState(() {
      _selectedCategoryId = category.sId;
    });

    ref.read(flashcardSettingsNotifierProvider.notifier).setCategoryDetails(
          categoryId: category.sId,
          categoryGroup: category.group,
          categorySubject: category.subject,
          categoryLesson: category.lesson,
        );

    widget.onCategorySelected(category.sId!);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.l10n!.selectCategory,
            style: theme.textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSecondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
            ),
            onPressed: widget.onClose,
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
        body: FadeTransition(
          opacity: _fadeInAnimation,
          child: categoriesAsync.when(
            data: (categories) => _buildContent(context, categories),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const Gap(16),
                  Text(
                    '${context.l10n!.error}: $error',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Category> categories) {
    final notifier = ref.read(categoriesProvider.notifier);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final groups = notifier.getUniqueGroups(categories);
    final subjects = notifier.getUniqueSubjects(categories, _selectedGroup);
    final lessons =
        notifier.getUniqueLessons(categories, _selectedGroup, _selectedSubject);

    final filteredCategories = categories.where((c) {
      if (_selectedGroup != null && c.group != _selectedGroup) return false;
      if (_selectedSubject != null && c.subject != _selectedSubject) {
        return false;
      }
      if (_selectedLesson != null && c.lesson != _selectedLesson) return false;
      return true;
    }).toList();

    final hasFilter = _selectedGroup != null;

    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? theme.cardColor.withOpacity(0.5)
                : theme.colorScheme.secondary.withOpacity(0.05),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterDropdown(
                  context,
                  context.l10n!.group,
                  Icons.category_outlined,
                  _selectedGroup,
                  groups,
                  (value) {
                    setState(() {
                      _selectedGroup = value;
                      _selectedSubject = null;
                      _selectedLesson = null;
                      _selectedCategoryId = null;
                    });
                  },
                ),
                if (_selectedGroup != null && subjects.isNotEmpty) ...[
                  const Gap(8),
                  _buildFilterDropdown(
                    context,
                    context.l10n!.subject,
                    Icons.menu_book_outlined,
                    _selectedSubject,
                    subjects,
                    (value) {
                      setState(() {
                        _selectedSubject = value;
                        _selectedLesson = null;
                        _selectedCategoryId = null;
                      });
                    },
                  ),
                ],
                if (_selectedSubject != null && lessons.isNotEmpty) ...[
                  const Gap(8),
                  _buildFilterDropdown(
                    context,
                    context.l10n!.lesson,
                    Icons.bookmark_outline,
                    _selectedLesson,
                    lessons,
                    (value) {
                      setState(() {
                        _selectedLesson = value;
                        _selectedCategoryId = null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${filteredCategories.length}',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (hasFilter)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedGroup = null;
                      _selectedSubject = null;
                      _selectedLesson = null;
                      _selectedCategoryId = null;
                    });
                  },
                  icon: Icon(
                    Icons.refresh,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    context.l10n!.resetFilter,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: filteredCategories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const Gap(16),
                      Text(
                        context.l10n!.noCategoriesAvailable,
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(8),
                      Text(
                        context.l10n!.tryAgainLater,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ListView.builder(
                    key: ValueKey<String>(
                        '${_selectedGroup}_${_selectedSubject}_$_selectedLesson'),
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      return _buildCategoryItem(
                          context, filteredCategories[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context,
    String label,
    IconData icon,
    String? selectedValue,
    List<String> items,
    Function(String?) onChanged,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: selectedValue != null
            ? theme.colorScheme.secondary.withOpacity(0.1)
            : theme.colorScheme.onSecondary.withOpacity(0.1),
        border: Border.all(
          color: selectedValue != null
              ? theme.colorScheme.secondary
              : Colors.transparent,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const Gap(6),
              Text(
                label,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          style: theme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.secondary,
          ),
          dropdownColor: theme.scaffoldBackgroundColor,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: item == selectedValue
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, Category category) {
    final isSelected = category.sId == _selectedCategoryId;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectCategory(category),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.secondary
                    : theme.unselectedWidgetColor.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? theme.colorScheme.secondary.withOpacity(0.1)
                  : isDarkMode
                      ? theme.cardColor
                      : theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.secondary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Left side with radio and selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.secondary
                          : theme.unselectedWidgetColor.withOpacity(0.5),
                      width: 2,
                    ),
                    color: isSelected
                        ? theme.colorScheme.secondary.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        )
                      : null,
                ),

                const Gap(16),

                // Content with improved hierarchy
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "subject - lesson" as the main title
                      Text(
                        category.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color:
                              isSelected ? theme.colorScheme.secondary : null,
                        ),
                      ),

                      const Gap(4),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (category.group != null &&
                              category.group!.isNotEmpty)
                            _buildCategoryChip(
                              category.group!,
                              Icons.category_outlined,
                              isSelected,
                            ),
                          if (category.type != null &&
                              category.type!.isNotEmpty)
                            _buildCategoryChip(
                              category.type!,
                              Icons.school_outlined,
                              isSelected,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selected indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, bool isSelected) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.secondary.withOpacity(0.1)
            : theme.colorScheme.onSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isSelected
                ? theme.colorScheme.secondary
                : theme.colorScheme.onSurface,
          ),
          const Gap(4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
