import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../model/flashcard_model.dart';
import '../viewmodel/flashcard_item_count_provider.dart';
import 'flashcard_session_provider.dart';

class FlashcardItem extends ConsumerWidget {
  final Flashcard flashcard;
  final VoidCallback onTap;

  const FlashcardItem({
    super.key,
    required this.flashcard,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, ref) {
    final countAsync =
        ref.watch(flashcardItemCountProvider(flashcard.sId ?? ''));
    final studySessionsAsync =
        ref.watch(flashcardStudySessionsProvider(flashcard.sId ?? ''));

    final itemCount = countAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    final studySessions = studySessionsAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    // Get brightness to determine if we're in dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Theme.of(context).colorScheme.onSecondary.withOpacity(0.2)
              : Colors.grey.shade300,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Study Stats Banner (only shows if studied today)

          // Main card content
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft:
                  studySessions > 0 ? Radius.zero : const Radius.circular(16),
              topRight:
                  studySessions > 0 ? Radius.zero : const Radius.circular(16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.only(
                topLeft:
                    studySessions > 0 ? Radius.zero : const Radius.circular(16),
                topRight:
                    studySessions > 0 ? Radius.zero : const Radius.circular(16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
              splashColor:
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              highlightColor:
                  Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (studySessions > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 4),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                    size: 18,
                                  ),
                                  const Gap(8),
                                  Text(
                                    'Today $studySessions times studied',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? Colors.black
                                                : Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          const Gap(8),
                          // Flashcard title
                          Text(
                            flashcard.title ?? 'Untitled Flashcard',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const Gap(16),

                          // Author info and study status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Author info
                              Expanded(
                                child: Row(
                                  children: [
                                    // Avatar with gradient background
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ],
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          child: Text(
                                            (flashcard.studentId?.name
                                                        ?.isNotEmpty ==
                                                    true)
                                                ? flashcard.studentId!.name![0]
                                                    .toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const Gap(8),

                                    Flexible(
                                      child: Text(
                                        flashcard.studentId?.name ?? 'Unknown',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Gap(10),
                              // Study indicator for unstudied cards
                              if (studySessions == 0)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_circle_outline,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    const Gap(4),
                                    Text(
                                      'Tap to study',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        itemCount == 0 ? "Private" : '$itemCount items',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
