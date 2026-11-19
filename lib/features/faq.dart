import 'package:flutter/material.dart';
import 'package:prostuti/common/widgets/common_widgets/common_widgets.dart';
import 'package:prostuti/core/services/localization_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> with CommonWidgets {
  // Track which FAQ items are expanded
  final Map<int, bool> _expandedItems = {
    0: false,
    1: false,
    2: false,
    3: false,
    4: false
  };

  // List of FAQ items (localized, so built per-frame from context)
  List<Map<String, String>> _faqItems(BuildContext context) {
    final l10n = context.l10n!;
    return [
      {'question': l10n.faqQuestion1, 'answer': l10n.faqAnswer1},
      {'question': l10n.faqQuestion2, 'answer': l10n.faqAnswer2},
      {'question': l10n.faqQuestion3, 'answer': l10n.faqAnswer3},
      {'question': l10n.faqQuestion4, 'answer': l10n.faqAnswer4},
      {'question': l10n.faqQuestion5, 'answer': l10n.faqAnswer5},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final faqItems = _faqItems(context);

    return Scaffold(
      appBar: commonAppbar(context.l10n!.faq),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  itemCount: faqItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildFAQItem(
                      index,
                      faqItems[index]['question'] ?? '',
                      faqItems[index]['answer'] ?? '',
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  // Launch email to support
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'support@prostuti.app',
                    query:
                        'subject=FAQ Question&body=I have a question regarding...',
                  );

                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  context.l10n!.faqAskQuestion,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(int index, String question, String answer) {
    bool isExpanded = _expandedItems[index] ?? false;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header with toggle
          InkWell(
            onTap: () {
              setState(() {
                _expandedItems[index] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),

          // Answer content (only shown when expanded)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
