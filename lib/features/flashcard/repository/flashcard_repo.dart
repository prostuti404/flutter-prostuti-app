import 'package:dartz/dartz.dart';
import 'package:prostuti/core/services/dio_service.dart';
import 'package:prostuti/core/services/error_handler.dart';
import 'package:prostuti/core/services/error_response.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/category_model.dart';
import '../model/create_flash_card.dart';
import '../model/flashcard_model.dart';

part 'flashcard_repo.g.dart';

@riverpod
FlashcardRepo flashcardRepo(FlashcardRepoRef ref) {
  final dioService = ref.watch(dioServiceProvider);
  return FlashcardRepo(dioService);
}

class FlashcardRepo {
  final DioService _dioService;

  FlashcardRepo(this._dioService);

  Future<Either<ErrorResponse, FlashcardResponse>> getAllFlashcards({
    int page = 1,
    int limit = 10,
    required String visibility,
    String? categoryGroup,
    String? categorySubject,
    String? categoryLesson,
    String? searchTerm,
  }) async {
    final queryParams = <String, dynamic>{
      "page": page,
      "limit": limit,
      "visibility": visibility,
      "isApproved": true,
    };

    // Cascading Group -> Subject -> Lesson filters (API doc section 2.3).
    void addIfPresent(String key, String? value) {
      if (value != null && value.isNotEmpty) queryParams[key] = value;
    }

    addIfPresent("categoryGroup", categoryGroup);
    addIfPresent("categorySubject", categorySubject);
    addIfPresent("categoryLesson", categoryLesson);
    addIfPresent("searchTerm", searchTerm);

    final response = await _dioService.getRequest(
      "/flashcard/all-flashcard",
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      return Right(FlashcardResponse.fromJson(response.data));
    } else {
      final errorResponse = ErrorResponse.fromJson(response.data);
      ErrorHandler().setErrorMessage(errorResponse.message);
      return Left(errorResponse);
    }
  }

  Future<Either<ErrorResponse, FlashcardResponse>> searchFlashcards(
      String query, String visibility) async {
    return getAllFlashcards(
      visibility: visibility,
      searchTerm: query,
    );
  }

  /// Records a swipe on a deck item: `right` = known, `left` = needs review.
  Future<Either<ErrorResponse, bool>> swipeFlashcardItem(
      String itemId, String swipeDirection) async {
    final response = await _dioService.patchRequest(
      "/flashcard/swipe-flashcard-item/$itemId",
      data: {"swipeDirection": swipeDirection},
    );

    if (response.statusCode == 200) {
      return const Right(true);
    } else {
      final errorResponse = ErrorResponse.fromJson(response.data);
      ErrorHandler().setErrorMessage(errorResponse.message);
      return Left(errorResponse);
    }
  }

  // New method for creating a flashcard
  Future<Either<ErrorResponse, Map<String, dynamic>>> createFlashcard(
      CreateFlashcardRequest request) async {
    final response = await _dioService.postRequest(
      "/flashcard/create-flashcard",
      request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Right(response.data);
    } else {
      final errorResponse = ErrorResponse.fromJson(response.data);
      ErrorHandler().setErrorMessage(errorResponse.message);
      return Left(errorResponse);
    }
  }

  Future<Either<ErrorResponse, bool>> toggleFavoriteFlashcardItem(
      String itemId) async {
    final response = await _dioService
        .patchRequest("/flashcard/favorite-flashcard-item/$itemId");

    if (response.statusCode == 200) {
      return const Right(true);
    } else {
      final errorResponse = ErrorResponse.fromJson(response.data);
      ErrorHandler().setErrorMessage(errorResponse.message);
      return Left(errorResponse);
    }
  }

// Update the getFavoriteFlashcardItems method to parse the response correctly:

  Future<Either<ErrorResponse, List<String>>>
      getFavoriteFlashcardItems() async {
    try {
      print('Fetching favorite flashcard items');

      final response =
          await _dioService.getRequest("/flashcard/favorite-flashcard-items");

      print('Get favorites API response status: ${response.statusCode}');
      print('Get favorites response data: ${response.data}');

      if (response.statusCode == 200) {
        // The data field is a list of complete flashcard item objects, not just IDs
        final List<dynamic> items = response.data['data'] ?? [];

        // Extract the _id from each item
        final List<String> favoriteIds =
            items.map<String>((item) => item['_id'].toString()).toList();

        print('Parsed favorite IDs: $favoriteIds');
        return Right(favoriteIds);
      } else {
        final errorResponse = ErrorResponse.fromJson(response.data);
        ErrorHandler().setErrorMessage(errorResponse.message);
        print('Error getting favorites: ${errorResponse.message}');
        return Left(errorResponse);
      }
    } catch (e) {
      print('Exception in getFavoriteFlashcardItems: $e');
      return Left(ErrorResponse(success: false, message: e.toString()));
    }
  }

  Future<Either<ErrorResponse, CategoryResponse>> getCategories() async {
    try {
      final response = await _dioService.getRequest(
        "/category",
        queryParameters: {"onlyCreated": true, "limit": 0},
      );

      if (response.statusCode == 200) {
        return Right(CategoryResponse.fromJson(response.data));
      } else {
        final errorResponse = ErrorResponse.fromJson(response.data);
        ErrorHandler().setErrorMessage(errorResponse.message);
        return Left(errorResponse);
      }
    } catch (e) {
      return Left(ErrorResponse(success: false, message: e.toString()));
    }
  }
}
