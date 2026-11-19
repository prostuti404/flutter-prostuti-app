import 'package:dartz/dartz.dart' show Right;
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gap/gap.dart';
import 'package:prostuti/common/widgets/common_widgets/common_widgets.dart';
import 'package:prostuti/core/services/localization_service.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../../core/services/error_response.dart';
import '../../../core/services/nav.dart';
import '../../../core/services/size_config.dart';
import '../../home_screen/view/home_screen_view.dart';
import '../model/flashcard_details_model.dart';
import '../repository/flashcard_repo.dart';
import '../services/flashcard_tracker.dart';
import '../viewmodel/flashcard_details_viewmodel.dart';
import '../viewmodel/flashcard_favourite_viewmodel.dart';
import '../widgets/flashcard_card.dart';

class FlashcardStudyView extends ConsumerStatefulWidget {
  final String flashcardId;
  final String flashcardTitle;

  const FlashcardStudyView({
    super.key,
    required this.flashcardId,
    required this.flashcardTitle,
  });

  @override
  FlashcardStudyViewState createState() => FlashcardStudyViewState();
}

class FlashcardStudyViewState extends ConsumerState<FlashcardStudyView>
    with CommonWidgets {
  final SwipableStackController _controller = SwipableStackController();
  final FlutterTts flutterTts = FlutterTts();
  final List<GlobalKey<FlipCardState>> _cardKeys = [];
  bool _showAnswer = false;
  int _currentIndex = 0;

  final FlashcardStudyTracker _tracker = FlashcardStudyTracker();

  void _toggleFavorite(String itemId) {
    // Call the API through the provider
    ref.read(favoriteFlashcardsProvider.notifier).toggleFavorite(itemId);
  }

  @override
  void initState() {
    super.initState();
    _initTts();
    _tracker.reset();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoriteFlashcardsProvider.notifier).refreshFavorites();
    });
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("bn-BD");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _onSwipeCompleted(int index, SwipeDirection direction) {
    setState(() {
      _currentIndex = index;
      _showAnswer = false;
    });

    // Get the current flashcard item
    final flashcardDetailAsync =
        ref.read(flashcardDetailNotifierProvider(widget.flashcardId));
    flashcardDetailAsync.whenData((flashcardDetail) {
      final items = flashcardDetail.items ?? [];
      if (items.isNotEmpty) {
        final actualIndex = index % items.length;
        final item = items[actualIndex];

        // Persist the learn/known swipe once per card per session. Failures
        // are non-fatal: studying must keep working if tracking cannot sync.
        final swipeDirection = switch (direction) {
          SwipeDirection.right => 'right',
          SwipeDirection.left => 'left',
          _ => null,
        };
        if (swipeDirection != null &&
            item.sId != null &&
            !_tracker.processedCardIds.contains(item.sId)) {
          ref
              .read(flashcardRepoProvider)
              .swipeFlashcardItem(item.sId!, swipeDirection)
              .catchError((Object _) => const Right<ErrorResponse, bool>(false));
        }

        // Record the swipe in the tracker
        _tracker.recordSwipe(item.sId!, direction);

        // Check if all cards have been processed
        _tracker.checkCompletion(
          context,
          flashcardDetail,
          widget.flashcardId,
          widget.flashcardTitle,
        );
      }
    });

    // Process swipe direction logic
    if (direction == SwipeDirection.left) {
      // "Learn" logic
      print("Swiped Left (Learn)");
    } else if (direction == SwipeDirection.right) {
      // "Know" logic
      print("Swiped Right (Know)");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _nextCard() {
    if (_showAnswer) {
      setState(() {
        _showAnswer = false;
      });
    }
    _controller.next(swipeDirection: SwipeDirection.right);
  }

  void _previousCard() {
    if (_showAnswer) {
      setState(() {
        _showAnswer = false;
      });
    }
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  // Colors for the flashcards (using three from the design)
  final List<Color> _cardColors = [
    const Color(0xFFC084FC),
    const Color(0xFF656058),
    const Color(0xFFF97316),
    const Color(0xFF652E07),
    const Color(0xFF534D65),
  ];

  Color _getCardColor(int index) {
    return _cardColors[index % _cardColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final flashcardDetailAsync =
        ref.watch(flashcardDetailNotifierProvider(widget.flashcardId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.flashcardTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
            onPressed: () {
              Nav().push(const HomeScreen(
                initialIndex: 1,
              ));
            },
            icon: const Icon(Icons.arrow_back)),
      ),
      body: flashcardDetailAsync.when(
        data: (flashcardDetail) {
          final items = flashcardDetail.items ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(context.l10n!.emptyFlashcardMessage),
            );
          }

          // Ensure we have enough card keys
          if (_cardKeys.length < items.length) {
            for (int i = _cardKeys.length; i < items.length; i++) {
              _cardKeys.add(GlobalKey<FlipCardState>());
            }
          }

          return Column(
            children: [
              // Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 16),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //     children: [
              //       IconButton(
              //         icon: Icon(
              //           Icons.arrow_back_ios_rounded,
              //           color: Theme.of(context).colorScheme.primary,
              //           size: 30,
              //         ),
              //         onPressed: _previousCard,
              //       ),
              //       Text(
              //         context.l10n!.swipe,
              //         style: Theme.of(context).textTheme.titleMedium!.copyWith(
              //               fontWeight: FontWeight.bold,
              //             ),
              //       ),
              //       InkWell(
              //         onTap: _nextCard,
              //         child: SvgPicture.asset(
              //           "assets/icons/flashcard_next.svg",
              //           fit: BoxFit.cover,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildStackedCards(items),
                ),
              ),
              const Gap(16),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            'Warning',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          content: Text(
                            'All progress will be reset if you leave this screen.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text(
                                'Cancel',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                                Nav().push(
                                  const HomeScreen(
                                    initialIndex: 1,
                                  ),
                                );
                              },
                              child: Text(
                                'Continue',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(
                              color: Color(0xff155EEF), width: 3),
                          borderRadius: BorderRadius.circular(4)),
                      backgroundColor: const Color(0xffD1E0FF),
                      fixedSize: Size(SizeConfig.w(356), SizeConfig.h(40))),
                  child: Text(
                    context.l10n!.viewCardList,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: const Color(0xff2970FF),
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
            child: CircularProgressIndicator(
          semanticsLabel: context.l10n!.loading,
          color: Theme.of(context).colorScheme.secondary,
        )),
        error: (error, stack) => Center(
          child: Text('${context.l10n!.error}: ${error.toString()}'),
        ),
      ),
    );
  }

  // New method to build stacked cards
  Widget _buildStackedCards(List<dynamic> items) {
    return Stack(
      children: [
        // Add background cards (visible behind the current card)
        ..._buildBackgroundCards(items),

        // Main swipable stack (current card)
        SwipableStack(
          controller: _controller,
          onSwipeCompleted: _onSwipeCompleted,
          overlayBuilder: (context, properties) {
            // Show overlay instructions when swiping
            final direction = properties.direction;
            if (direction == null) return const SizedBox.shrink();

            if (direction == SwipeDirection.left) {
              return _buildSwipeOverlay(
                context.l10n!.swipeLeftToLearn,
                direction,
                const Color(0xFF60A5FA),
              );
            } else if (direction == SwipeDirection.right) {
              return _buildSwipeOverlay(
                context.l10n!.swipeRightToKnow,
                direction,
                const Color(0xFF60A5FA),
              );
            }

            return const SizedBox.shrink();
          },
          builder: (context, properties) {
            final index = properties.index;
            final actualIndex = index % items.length;
            final FlashcardItem item = items[actualIndex];

            // IMPORTANT: Create a unique key for each position in the stack
            // This ensures we don't reuse keys across cards
            final key = GlobalKey<FlipCardState>();

            // Get favorite status from provider
            final favoritesAsync = ref.watch(favoriteFlashcardsProvider);
            final isFavorite = favoritesAsync.when(
              data: (favorites) => favorites.contains(item.sId),
              loading: () => false,
              error: (_, __) => false,
            );

            // Use our FlashCard with TTS and Favorite buttons
            return FlashCard(
              frontText: item.term!,
              backText: item.answer!,
              flipKey: key,
              // Use the newly created key
              isFavorite: isFavorite,
              onTts: () {
                final textToSpeak = key.currentState?.isFront == true
                    ? item.term!
                    : item.answer!;
                _speak(textToSpeak);
              },
              onFavorite: () => _toggleFavorite(item.sId!),
              backgroundColor: _getCardColor(actualIndex),
            );
          },
        ),
      ],
    );
  }

  // Build the background cards that are visible behind the current card
  List<Widget> _buildBackgroundCards(List<dynamic> items) {
    List<Widget> backgroundCards = [];

    // Only build background cards if there are more cards coming up
    if (items.length > _currentIndex + 1) {
      // Add the next 2 cards (or as many as available)
      for (int i = 1; i <= 2; i++) {
        if (_currentIndex + i < items.length) {
          final nextIndex = (_currentIndex + i) % items.length;
          final item = items[nextIndex];

          // Calculate decreasing sizes and offsets for stacked effect
          final topOffset =
              -50.0 * i; // Each card is peeking out 50 pixels from the top
          final scale = 1.0 - (0.03 * i); // Each card is slightly smaller

          backgroundCards.add(
            Positioned(
              top: topOffset,
              left: 0,
              right: 0,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: 0.8 - (0.1 * i),
                  // Fade out cards further back but keep them more visible
                  child: Container(
                    height: MediaQuery.of(context).size.height *
                        0.6, // Similar height to main card
                    decoration: BoxDecoration(
                      color: _getCardColor(nextIndex),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // Return in reverse order so the card closest to top is drawn last (on top)
    return backgroundCards.reversed.toList();
  }

  Widget _buildSwipeOverlay(
      String text, SwipeDirection direction, Color color) {
    return Center(
      child: Container(
        height: 180,
        width: 180,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              direction == SwipeDirection.left
                  ? Icons.arrow_back_rounded
                  : Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 60,
            ),
            const Gap(16),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
