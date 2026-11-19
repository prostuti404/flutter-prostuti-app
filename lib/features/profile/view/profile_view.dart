import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:prostuti/common/helpers/theme_provider.dart';
import 'package:prostuti/common/widgets/common_widgets/common_widgets.dart';
import 'package:prostuti/core/services/nav.dart';
import 'package:prostuti/features/auth/login/view/login_view.dart';
import 'package:prostuti/features/faq.dart';
import 'package:prostuti/features/privacy_policy_screen.dart';
import 'package:prostuti/features/profile/view/test_history_view.dart';
import 'package:prostuti/features/support_screen.dart';
import 'package:prostuti/features/term_condition.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../common/view_model/auth_notifier.dart';
import '../../../core/configs/app_colors.dart';
import '../../../core/services/localization_service.dart';
import '../../auth/category/view/category_view.dart';
import '../../course/my_course/view/my_course_view.dart';
import '../../payment/view/subscription_view.dart';
import '../../payment/viewmodel/check_subscription.dart';
import '../repository/profile_repo.dart';
import '../viewmodel/profile_viewmodel.dart';
import '../widgets/ProfileSkeleton.dart';
import '../widgets/custom_list_tile.dart';
import '../widgets/logout_button.dart';
import 'change_password_view.dart';
import 'favourite_view.dart';

class UserProfileView extends ConsumerWidget with CommonWidgets {
  UserProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDarkTheme = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final userProfileAsyncValue = ref.watch(userProfileProvider);
    final subscriptionAsyncValue = ref.watch(userSubscribedProvider);

    // Get current locale
    final currentLocale = ref.watch(localeProvider);
    final currentLanguage = languages.firstWhere(
      (lang) => lang.code == currentLocale.languageCode,
      orElse: () => languages[1], // Default to Bangla
    );

    return Scaffold(
      appBar: commonAppbar(context.l10n!.myProfile),
      body: userProfileAsyncValue.when(
        data: (userData) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: userData.data!.image == null
                          ? const AssetImage('assets/images/test_dp.jpg')
                              as ImageProvider
                          : CachedNetworkImageProvider(
                              userData.data!.image!.path!),
                    ),
                    const Gap(8),
                    Text(
                      '${userData.data!.name}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    const Gap(24),
                    subscriptionAsyncValue.when(
                      data: (data) {
                        return InkWell(
                          onTap: data
                              ? () {}
                              : () => Nav().push(SubscriptionView()),
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * .081,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              image: const DecorationImage(
                                image: AssetImage(
                                    "assets/images/upgrade_to_premium_background.png"),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                    "assets/icons/premium_upgrade.svg"),
                                const Gap(24),
                                Text(
                                  data
                                      ? context.l10n!.youAreOnPremiumPlan
                                      : context.l10n!.upgradeToPremium,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              AppColors.textActionPrimaryLight),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      error: (error, stackTrace) {
                        return Text(error.toString());
                      },
                      loading: () {
                        return Skeletonizer(
                          enableSwitchAnimation: true,
                          enabled: true,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * .081,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                    "assets/icons/premium_upgrade.svg"),
                                const Gap(24),
                                Text(
                                  context.l10n!.upgradeToPremium,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              AppColors.textActionPrimaryLight),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),
              const Gap(24),
              // CustomListTile(
              //   icon: "assets/icons/your_point.svg",
              //   title: context.l10n!.yourPoints,
              //   onTap: () {},
              // ),

              CustomListTile(
                icon: isDarkTheme
                    ? "assets/icons/category_dark.svg"
                    : "assets/icons/category.svg",
                title: context.l10n!.category,
                onTap: () {
                  // Navigate to CategoryView in update mode with the studentId
                  final studentId = userData.data?.studentId;
                  Nav().push(CategoryView(
                    isRegistration: false,
                    studentId: studentId,
                  ));
                },
                // Show current category if available
                trailing: userData.data?.categoryType != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userData.data!.categoryType!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      )
                    : null,
              ).animate().moveX(duration: const Duration(milliseconds: 600)),
              const Gap(24),
              Text(
                context.l10n!.account,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ).animate().moveY(duration: const Duration(milliseconds: 600)),
              const Gap(10),
              CustomListTile(
                      icon: isDarkTheme
                          ? "assets/icons/user_dark.svg"
                          : "assets/icons/user.svg",
                      title: context.l10n!.profileInformation,
                      onTap: () {
                        Nav().push(const ChangePasswordView());
                      })
                  .animate()
                  .moveX(duration: const Duration(milliseconds: 600)),
              CustomListTile(
                icon: isDarkTheme
                    ? "assets/icons/language-square_dark.svg"
                    : "assets/icons/language.svg",
                title: context.l10n!.language,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentLanguage.localName,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap: () => _showLanguageSelector(context, ref),
              ).animate().moveX(duration: const Duration(milliseconds: 600)),
              const Gap(24),
              Text(
                context.l10n!.myItems,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ).animate().moveY(duration: const Duration(milliseconds: 600)),
              const Gap(10),
              CustomListTile(
                      icon: isDarkTheme
                          ? "assets/icons/books-01.svg"
                          : "assets/icons/courses.svg",
                      title: context.l10n!.myCourses,
                      onTap: () {
                        Nav().push(MyCourseView());
                      })
                  .animate()
                  .moveX(duration: const Duration(milliseconds: 600)),
              CustomListTile(
                      icon: isDarkTheme
                          ? "assets/icons/favourite_dark.svg"
                          : "assets/icons/favourites_profile.svg",
                      title: context.l10n!.favorites,
                      onTap: () {
                        Nav().push(const FavoriteItemsView());
                      })
                  .animate()
                  .moveX(duration: const Duration(milliseconds: 600)),
              CustomListTile(
                      icon: isDarkTheme
                          ? "assets/icons/catalogue_dark.svg"
                          : "assets/icons/progress_history.svg",
                      title: context.l10n!.testHistory,
                      onTap: () {
                        Nav().push(TestHistoryScreen(
                          studentId: "${userData.data!.sId}",
                        ));
                      })
                  .animate()
                  .moveX(duration: const Duration(milliseconds: 600)),
              const Gap(24),
              Text(
                context.l10n!.settings,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Gap(10),
              Card(
                color: Theme.of(context).colorScheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(
                        width: 2, color: AppColors.shadeNeutralLight)),
                child: ListTile(
                  leading: SvgPicture.asset(
                    isDarkTheme
                        ? "assets/icons/moon-eclipse_dark.svg"
                        : "assets/icons/dark_theme.svg",
                    fit: BoxFit.cover,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  title: Text(context.l10n!.darkTheme),
                  trailing: Switch(
                    value: isDarkTheme,
                    activeTrackColor: AppColors.textActionSecondaryLight,
                    activeColor: Colors.white,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: AppColors.borderNormalLight,
                    onChanged: (bool value) {
                      ref
                          .read(themeNotifierProvider.notifier)
                          .toggleTheme(context);
                    },
                  ),
                ),
              ),
              const Gap(24),
              Text(
                context.l10n!.others,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Gap(10),
              // CustomListTile(
              //     icon: "assets/icons/subscription.svg",
              //     title: context.l10n!.subscription,
              //     onTap: () {}),
              CustomListTile(
                  icon: isDarkTheme
                      ? "assets/icons/customer-support_dark.svg"
                      : "assets/icons/customer-support.svg",
                  title: context.l10n!.support,
                  onTap: () {
                    Nav().push(const SupportScreen());
                  }),
              CustomListTile(
                  icon: isDarkTheme
                      ? "assets/icons/help-circle_dark.svg"
                      : "assets/icons/f_and_q.svg",
                  title: context.l10n!.faq,
                  onTap: () {
                    Nav().push(const FAQScreen());
                  }),
              CustomListTile(
                  icon: isDarkTheme
                      ? "assets/icons/alert-circle_dark.svg"
                      : "assets/icons/terms.svg",
                  title: context.l10n!.termsAndConditions,
                  onTap: () {
                    Nav().push(const TermsConditionsScreen());
                  }),
              CustomListTile(
                  icon: isDarkTheme
                      ? "assets/icons/security_dark.svg"
                      : "assets/icons/privacy.svg",
                  title: context.l10n!.privacyPolicy,
                  onTap: () {
                    Nav().push(const PrivacyPolicyScreen());
                  }),
              const Gap(24),
              LogoutButton(
                onPressed: () async {
                  final authNotifier = ref.read(authNotifierProvider.notifier);
                  await authNotifier.clearTokens();
                  Nav().pushAndRemoveUntil(const LoginView());
                },
              ),
              const Gap(12),
              TextButton(
                onPressed: () => _confirmDeleteAccount(context, ref),
                child: Text(
                  context.l10n!.deleteAccount,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(color: Colors.red),
                ),
              ),
            ],
          );
        },
        error: (error, stackTrace) {
          print("Error : $error");
          print("stackTrace : $stackTrace");
          return Text("${context.l10n!.error}: $error");
        },
        loading: () {
          return const ProfileSkeleton();
        },
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n!.deleteAccountTitle),
        content: Text(dialogContext.l10n!.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              dialogContext.l10n!.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(profileRepoProvider).deleteAccount();
    if (!context.mounted) return;

    await result.fold(
      (error) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
      (_) async {
        // Wipes tokens and local prefs, then returns to the login screen.
        await ref.read(authNotifierProvider.notifier).clearTokens();
        Fluttertoast.showToast(msg: context.l10n!.accountDeleted);
        Nav().pushAndRemoveUntil(const LoginView());
      },
    );
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      context.l10n!.selectLanguage,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 48), // Balance space
                  ],
                ),
                const SizedBox(height: 24),

                // Language options
                ...languages.map((language) => _buildLanguageOption(
                    context, ref, language,
                    isSelected: currentLocale.languageCode == language.code)),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption(
      BuildContext context, WidgetRef ref, Language language,
      {required bool isSelected}) {
    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).changeLanguage(language.code);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2970FF).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2970FF)
                : Colors.grey.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language.localName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF2970FF) : null,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2970FF),
              ),
          ],
        ),
      ),
    );
  }
}
