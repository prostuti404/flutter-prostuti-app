import 'package:dartz/dartz.dart';
import 'package:prostuti/core/services/api_response.dart';
import 'package:prostuti/core/services/dio_service.dart';
import 'package:prostuti/core/services/error_handler.dart';
import 'package:prostuti/core/services/error_response.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/category_model.dart';

part 'category_repo.g.dart';

@riverpod
CategoryRepo categoryRepo(CategoryRepoRef ref) {
  final dioService = ref.watch(dioServiceProvider);
  return CategoryRepo(dioService);
}

class CategoryRepo {
  final DioService _dioService;

  CategoryRepo(this._dioService);

  /// `GET /auth/registration-categories` — the main categories a student can
  /// register under, each with its sub-categories. Public; no token needed.
  ///
  /// Does not push the failure into [ErrorHandler]: the caller falls back to
  /// [RegistrationCategory.fallback] rather than surfacing an error, since a
  /// missing list is not something the user can act on mid-registration.
  Future<Either<ErrorResponse, List<RegistrationCategory>>>
      getRegistrationCategories() async {
    final response =
        await _dioService.getRequest("/auth/registration-categories");

    if (response.statusCode == 200) {
      final data = response.data['data'];
      if (data is! List) {
        return Left(ErrorResponse(
          success: false,
          message: "Unexpected registration categories format",
        ));
      }
      return Right(data
          .whereType<Map<String, dynamic>>()
          .map(RegistrationCategory.fromJson)
          .where((c) => c.mainCategory.isNotEmpty)
          .toList());
    }

    return Left(ErrorResponse(
      success: false,
      message: response.data is Map
          ? ErrorResponse.fromJson(response.data).message
          : "Could not load registration categories",
    ));
  }

  /// Updates the signed-in student's category.
  ///
  /// Note the payload key is `mainCategory`, not `categoryType` — the two
  /// endpoints disagree on the name for the same value, and this is the shape
  /// this one accepts. [subCategory] is only sent when one was picked.
  Future<ApiResponse> updateStudentCategory(
    String categoryType, {
    String? subCategory,
  }) async {
    final response = await _dioService.patchRequest(
      "/student/update-category",
      data: {
        "mainCategory": categoryType,
        if (subCategory != null && subCategory.isNotEmpty)
          "subCategory": subCategory,
      },
    );

    if (response.statusCode == 200) {
      return ApiResponse.success(response.data);
    }

    final errorResponse = ErrorResponse.fromJson(response.data);
    ErrorHandler().setErrorMessage(errorResponse.message);
    return ApiResponse.error(errorResponse);
  }
}
