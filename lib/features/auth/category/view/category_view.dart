import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gap/gap.dart';
import 'package:prostuti/common/widgets/common_widgets/common_widgets.dart';
import 'package:prostuti/common/widgets/long_button.dart';
import 'package:prostuti/core/configs/app_colors.dart';
import 'package:prostuti/core/services/debouncer.dart';
import 'package:prostuti/core/services/error_handler.dart';
import 'package:prostuti/core/services/localization_service.dart';
import 'package:prostuti/core/services/nav.dart';
import 'package:prostuti/features/auth/category/model/category_constant.dart';
import 'package:prostuti/features/auth/category/model/category_model.dart';
import 'package:prostuti/features/auth/category/repository/category_repo.dart';
import 'package:prostuti/features/auth/category/viewmodel/category_viewmodel.dart';
import 'package:prostuti/features/auth/login/view/login_view.dart';
import 'package:prostuti/features/auth/signup/repository/signup_repo.dart';
import 'package:prostuti/features/auth/signup/viewmodel/email_viewmodel.dart';
import 'package:prostuti/features/auth/signup/viewmodel/name_viewmodel.dart';
import 'package:prostuti/features/auth/signup/viewmodel/otp_viewmodel.dart';
import 'package:prostuti/features/auth/signup/viewmodel/password_viewmodel.dart';
import 'package:prostuti/features/auth/signup/viewmodel/phone_number_viewmodel.dart';
import 'package:prostuti/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:prostuti/generated/assets.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Category picker, used both as the last step of registration and from the
/// profile screen to change an existing category.
///
/// The options come from `GET /auth/registration-categories`: a main category
/// (Academic | Admission | Job) and, for the ones that carry them, a
/// sub-category (Science, Engineering, ...). Picking a main category with
/// sub-categories slides into a second list; "Job" has none and completes in
/// one step. Selecting is separate from submitting: tapping only marks a
/// choice, the confirm button commits it.
class CategoryView extends ConsumerStatefulWidget {
  final bool isRegistration;
  final String? studentId;

  const CategoryView({super.key, this.isRegistration = true, this.studentId});

  @override
  CategoryViewState createState() => CategoryViewState();
}

class CategoryViewState extends ConsumerState<CategoryView> with CommonWidgets {
  final _loadingProvider = StateProvider<bool>((ref) => false);
  final _debouncer = Debouncer(milliseconds: 120);

  String? _selectedCategory;
  String? _selectedSubCategory;

  /// The main category whose sub-categories are currently on screen, or null
  /// while the main list is showing.
  RegistrationCategory? _openCategory;

  @override
  void initState() {
    super.initState();

    // When changing the category from the profile, start from the current one.
    if (!widget.isRegistration) {
      _loadCurrentCategory();
    }
  }

  void _loadCurrentCategory() {
    Future.microtask(() async {
      ref.read(_loadingProvider.notifier).state = true;

      try {
        final userProfile = await ref.read(userProfileProvider.future);
        final current = userProfile.data?.categoryType;
        if (current != null && mounted) {
          setState(() => _selectedCategory = current);
        }
      } catch (e) {
        if (mounted) {
          _showMessage("${context.l10n!.anErrorOccurred}: $e");
        }
      } finally {
        if (mounted) {
          ref.read(_loadingProvider.notifier).state = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_loadingProvider);
    final categoriesAsync = ref.watch(registrationCategoriesProvider);
    final theme = Theme.of(context);
    final openCategory = _openCategory;

    // The sub-category list is a second "page" of the same screen: the app
    // bar's back arrow returns to the main list instead of leaving.
    return PopScope(
      canPop: openCategory == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSubCategories();
      },
      child: Scaffold(
        appBar: openCategory != null
            ? AppBar(
                title: Text(context.l10n!.subcategory),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _closeSubCategories,
                ),
              )
            : commonAppbar(widget.isRegistration
                ? context.l10n!.category
                : context.l10n!.updateCategory),
        body: Skeletonizer(
          enabled: isLoading || categoriesAsync.isLoading,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  openCategory != null
                      ? context.l10n!.pleaseSelectYourSubcategory
                      : context.l10n!.selectCategory,
                  style: theme.textTheme.titleMedium,
                ),
                const Gap(16),
                if (!widget.isRegistration && _selectedCategory != null)
                  _buildCurrentSelection(context),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(16)),
                    child: openCategory != null
                        ? _buildSubCategoryList(context, openCategory)
                        : _buildMainCategoryList(
                            context,
                            categoriesAsync.valueOrNull ??
                                RegistrationCategory.fallback,
                          ),
                  ),
                ),
                const Gap(16),
                LongButton(
                  text: context.l10n!.confirm,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A main category is enough on its own unless the backend lists
  /// sub-categories for it, in which case one of those must be picked too.
  bool get _canSubmit {
    if (_selectedCategory == null) return false;
    final category = _findCategory(_selectedCategory!);
    if (category != null && category.hasSubCategories) {
      return _selectedSubCategory != null;
    }
    return true;
  }

  RegistrationCategory? _findCategory(String mainCategory) {
    final categories = ref.read(registrationCategoriesProvider).valueOrNull ??
        RegistrationCategory.fallback;
    for (final c in categories) {
      if (c.mainCategory == mainCategory) return c;
    }
    return null;
  }

  Widget _buildMainCategoryList(
      BuildContext context, List<RegistrationCategory> categories) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategory == category.mainCategory;
        return _buildCategoryItem(
          context,
          label: _categoryLabel(context, category.mainCategory),
          leading: Image.asset(
            _categoryIcon(category.mainCategory),
            height: 40,
            width: 40,
          ),
          isSelected: isSelected,
          // A selected sub-category shows under its parent so the user can
          // see the full choice without re-opening the second list.
          subtitle: isSelected && _selectedSubCategory != null
              ? _subCategoryLabel(context, _selectedSubCategory!)
              : null,
          onSelect: () => _selectMainCategory(category),
        );
      },
    );
  }

  Widget _buildSubCategoryList(
      BuildContext context, RegistrationCategory category) {
    if (!category.hasSubCategories) {
      return Center(child: Text(context.l10n!.noSubcategoriesFound));
    }
    return ListView.builder(
      itemCount: category.subCategories.length,
      itemBuilder: (context, index) {
        final subCategory = category.subCategories[index];
        return _buildCategoryItem(
          context,
          label: _subCategoryLabel(context, subCategory),
          leading: Icon(_subCategoryIcon(subCategory),
              size: 32, color: _accent(context)),
          isSelected: _selectedSubCategory == subCategory,
          onSelect: () => setState(() {
            _selectedSubCategory = subCategory;
            _openCategory = null;
          }),
        );
      },
    );
  }

  void _selectMainCategory(RegistrationCategory category) {
    setState(() {
      if (_selectedCategory != category.mainCategory) {
        _selectedSubCategory = null;
      }
      _selectedCategory = category.mainCategory;
      _openCategory = category.hasSubCategories ? category : null;
    });
  }

  void _closeSubCategories() {
    setState(() => _openCategory = null);
  }

  Widget _buildCurrentSelection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: _accent(context)),
          const Gap(8),
          Expanded(
            child: Text(
              "${context.l10n!.currentCategory}: "
              "${_categoryLabel(context, _selectedCategory!)}"
              "${_selectedSubCategory != null ? ' - ${_subCategoryLabel(context, _selectedSubCategory!)}' : ''}",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context, {
    required String label,
    required Widget leading,
    required VoidCallback onSelect,
    required bool isSelected,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accent(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? accent.withOpacity(0.1)
            : theme.scaffoldBackgroundColor,
        border: Border.all(
            color: isSelected
                ? accent
                : (isDark
                    ? AppColors.borderNormalDark
                    : AppColors.borderNormalLight),
            width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: leading,
        title: Text(label),
        subtitle: subtitle == null ? null : Text(subtitle),
        onTap: onSelect,
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: isSelected ? accent : theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  void _submit() {
    if (_selectedCategory == null) {
      _showMessage(context.l10n!.pleaseSelectYourCategory);
      return;
    }
    if (!_canSubmit) {
      _showMessage(context.l10n!.pleaseSelectYourSubcategory);
      return;
    }

    if (widget.isRegistration) {
      _registerWithCategory();
    } else {
      _updateCategory();
    }
  }

  void _registerWithCategory() {
    _debouncer.run(
        action: () async {
          final email = ref.read(emailViewmodelProvider);

          final payload = {
            "otpCode": ref.read(otpProvider),
            "name": ref.read(nameViewmodelProvider),
            if (email.isNotEmpty) "email": email,
            "phone": "+88${ref.read(phoneNumberProvider)}",
            "password": ref.read(passwordViewmodelProvider),
            "confirmPassword": ref.read(passwordViewmodelProvider),
            "categoryType": _selectedCategory,
            if (_selectedSubCategory != null)
              "subCategory": _selectedSubCategory,
          };

          final response =
              await ref.read(signupRepoProvider).registerStudent(payload);

          if (!mounted) return;

          if (response.data != null) {
            Fluttertoast.showToast(msg: context.l10n!.signupSuccessful);
            Nav().pushAndRemoveUntil(const LoginView());
          } else {
            _showMessage(ErrorHandler().getErrorMessage());
            _debouncer.cancel();
            ErrorHandler().clearErrorMessage();
          }
        },
        loadingController: ref.read(_loadingProvider.notifier));
  }

  void _updateCategory() {
    _debouncer.run(
      action: () async {
        final response = await ref
            .read(categoryRepoProvider)
            .updateStudentCategory(_selectedCategory!,
                subCategory: _selectedSubCategory);

        if (!mounted) return;

        if (response.data != null) {
          ref.invalidate(userProfileProvider);
          Fluttertoast.showToast(msg: context.l10n!.categoryUpdatedSuccessfully);
          Navigator.pop(context);
        } else {
          _showMessage(ErrorHandler().getErrorMessage());
          _debouncer.cancel();
          ErrorHandler().clearErrorMessage();
        }
      },
      loadingController: ref.read(_loadingProvider.notifier),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// The accent the rest of the app uses for a selected/primary state.
  /// `Theme.of(context).primaryColor` is white in the light theme, so it cannot
  /// be used for borders or check marks here.
  Color _accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundActionPrimaryDark
          : AppColors.backgroundActionPrimaryLight;

  /// The wire value stays English; only the label is localized.
  String _categoryLabel(BuildContext context, String category) {
    switch (category) {
      case MainCategory.ACADEMIC:
        return context.l10n!.academic;
      case MainCategory.ADMISSION:
        return context.l10n!.admission;
      case MainCategory.JOB:
        return context.l10n!.job;
      default:
        return category;
    }
  }

  String _categoryIcon(String category) {
    switch (category) {
      case MainCategory.ADMISSION:
        return Assets.imagesMortarboard01;
      case MainCategory.JOB:
        return Assets.imagesBriefcase01;
      case MainCategory.ACADEMIC:
      default:
        return Assets.imagesBackpack03;
    }
  }

  /// Sub-category labels are matched case-insensitively because the backend
  /// serves display strings; anything unrecognised is shown as sent.
  String _subCategoryLabel(BuildContext context, String subCategory) {
    switch (subCategory.toLowerCase()) {
      case 'science':
        return context.l10n!.science;
      case 'commerce':
        return context.l10n!.commerce;
      case 'arts':
        return context.l10n!.arts;
      case 'engineering':
        return context.l10n!.engineering;
      case 'medical':
        return context.l10n!.medical;
      case 'university':
        return context.l10n!.university;
      default:
        return subCategory;
    }
  }

  IconData _subCategoryIcon(String subCategory) {
    switch (subCategory.toLowerCase()) {
      case 'science':
        return Icons.science_outlined;
      case 'commerce':
        return Icons.account_balance_wallet_outlined;
      case 'arts':
        return Icons.palette_outlined;
      case 'engineering':
        return Icons.engineering_outlined;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'university':
        return Icons.account_balance_outlined;
      default:
        return Icons.label_outline;
    }
  }
}
