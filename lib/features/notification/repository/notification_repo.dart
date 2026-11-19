import 'package:dartz/dartz.dart';
import 'package:prostuti/core/services/dio_service.dart';
import 'package:prostuti/core/services/error_handler.dart';
import 'package:prostuti/core/services/error_response.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/notification_model.dart';

part 'notification_repo.g.dart';

@riverpod
NotificationRepo notificationRepo(NotificationRepoRef ref) {
  final dioService = ref.watch(dioServiceProvider);
  return NotificationRepo(dioService);
}

class NotificationRepo {
  final DioService _dioService;

  NotificationRepo(this._dioService);

  Future<Either<ErrorResponse, NotificationModel>> getNotifications() async {
    try {
      final response = await _dioService.getRequest(
        "/student-notification",
      );

      if (response.statusCode == 200) {
        final notifications = NotificationModel.fromJson(response.data);
        return Right(notifications);
      } else {
        final errorResponse = ErrorResponse.fromJson(response.data);
        ErrorHandler().setErrorMessage(errorResponse.message);
        return Left(errorResponse);
      }
    } catch (e) {
      final errorResponse = ErrorResponse(
        message: e.toString(),
        success: false,
      );
      ErrorHandler().setErrorMessage(errorResponse.message);
      return Left(errorResponse);
    }
  }

  /// Marks a single notification as read (`PATCH /student-notification/:id`).
  Future<Either<ErrorResponse, bool>> markAsRead(String notificationId) async {
    try {
      final response =
          await _dioService.patchRequest("/student-notification/$notificationId");

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        final errorResponse = ErrorResponse.fromJson(response.data);
        ErrorHandler().setErrorMessage(errorResponse.message);
        return Left(errorResponse);
      }
    } catch (e) {
      final errorResponse = ErrorResponse(message: e.toString(), success: false);
      ErrorHandler().setErrorMessage(errorResponse.message);
      return Left(errorResponse);
    }
  }
}
