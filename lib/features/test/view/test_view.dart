import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:prostuti/core/services/localization_service.dart';
import 'package:prostuti/features/test/view/quizer_test_view.dart';
import 'package:prostuti/features/test/view/segment_test_view.dart';
import '../../../common/widgets/common_widgets/common_widgets.dart';
import '../../../core/services/nav.dart';
import '../widgets/test_nevigation_button.dart';
import 'mock_test_view.dart';

class TestLandingView extends StatelessWidget with CommonWidgets {
   TestLandingView({super.key});

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.l10n!.test
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: appTheme.appBarTheme.backgroundColor,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Text(
                context.l10n!.selectTestType,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Gap(16),
              Text(
                context.l10n!.testTypeDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: TestButton(
                        label: context.l10n!.segmentTest,
                        borderColor: borderColor,
                        svgAsset: 'assets/images/segment_test_background.svg',
                        icon: 'assets/icons/segment_icon.png',
                        onTap: () {
                          Nav().push( const SegmentTestLandingView());
                        },
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: TestButton(
                      label: context.l10n!.mockTest,
                      borderColor: borderColor,
                      svgAsset: 'assets/images/mock_test_background.svg',
                      icon: 'assets/icons/mock_icon.png',
                      onTap: () {
                        Nav().push( const MockTestLandingView());
                      },
                    ),
                  ),
                ],
              ),
              const Gap(12),
              TestButton(
                label: context.l10n!.quizer,
                borderColor: borderColor,
                svgAsset: 'assets/images/quizer_background.svg',
                icon: 'assets/icons/quizer_icon.png',
                fullWidth: true,
                onTap: () {
                  Nav().push( const QuizerTestLandingView());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

