// __brick__/repository/forget_password_repo.dart
import 'package:prostuti/core/services/dio_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:prostuti/core/services/error_handler.dart';
import 'package:prostuti/core/services/error_response.dart';

part 'forget_password_repo.g.dart';

@riverpod
ForgetPasswordRepo forgetPasswordRepo(ForgetPasswordRepoRef ref) {
  final dioService = ref.watch(dioServiceProvider);
  return ForgetPasswordRepo(dioService);
}

class ForgetPasswordRepo {
  final DioService _dioService;

  ForgetPasswordRepo(this._dioService);

  Future<bool> sendVerificationCodeForPasswordReset(
      {required String phoneNo}) async {
    final payload = {
      "phoneNumber": "+88$phoneNo",
      "phoneVerificationType": "PASSWORD_RESET"
    };

    final response = await _dioService.postRequest(
        "/phone-verification/send-verification-code", payload);

    if (response.statusCode == 200) {
      return response.data["success"];
    } else {
      final errorResponse = ErrorResponse.fromJson(response.data);
      ErrorHandler().setErrorMessage(errorResponse.message);
      return false;
    }
  }

  Future<bool> resetPassword({required Map<String, String> payload}) async {
    final response =
        await _dioService.postRequest("/auth/student/reset-password", payload);

    if (response.statusCode == 200) {
      return response.data["success"];
    } else {
      final errorResponse = ErrorResponse.fromJson(response.data);
      ErrorHandler().setErrorMessage(errorResponse.message);
      return false;
    }
  }
}
