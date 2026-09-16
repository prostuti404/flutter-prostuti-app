import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

import '../../../core/configs/app_colors.dart';
import '../../../core/services/localization_service.dart';

/// The wire values `subject_repo.dart` matches on to build the backend
/// query. Kept in English regardless of locale; only the on-screen label is
/// localized (see [QuestionStandardSelector._standardLabel]).
class QuestionStandard {
  static const String engineering = "Engineering";
  static const String university = "University";
  static const String medical = "Medical";
  static const String academic = "Academic";

  static const List<String> values = [
    engineering,
    university,
    medical,
    academic,
  ];
}

class QuestionStandardSelector extends StatelessWidget {
  final String selectedStandard;
  final ValueChanged<String> onStandardChanged;

  const QuestionStandardSelector({
    super.key,
    required this.selectedStandard,
    required this.onStandardChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStandardButton(
            context, QuestionStandard.engineering, "assets/icons/engineering.svg"),
        _buildStandardButton(
            context, QuestionStandard.university, "assets/icons/university.svg"),
        _buildStandardButton(
            context, QuestionStandard.medical, "assets/icons/medical.svg"),
        _buildStandardButton(
            context, QuestionStandard.academic, "assets/icons/academic.svg"),
      ],
    );
  }

  Widget _buildStandardButton(BuildContext context, String type, String icon) {
    final bool isSelected = selectedStandard == type;

    return InkWell(
      onTap: () => onStandardChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.backgroundActionPrimaryLight
              : AppColors.shadePrimaryLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.secondary,
              height: 20,
              width: 20,
            ),
            const Gap(8),
            Text(
              _standardLabel(context, type),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _standardLabel(BuildContext context, String type) {
    switch (type) {
      case QuestionStandard.engineering:
        return context.l10n!.engineering;
      case QuestionStandard.university:
        return context.l10n!.university;
      case QuestionStandard.medical:
        return context.l10n!.medical;
      case QuestionStandard.academic:
      default:
        return context.l10n!.academic;
    }
  }
}
