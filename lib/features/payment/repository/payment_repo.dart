import 'package:dartz/dartz.dart';
import 'package:prostuti/core/services/dio_service.dart';
import 'package:prostuti/core/services/error_response.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../common/models/student_profile.dart';
import '../../../core/services/error_handler.dart';
import '../model/subscription_plan_model.dart';
import '../model/voucher_model.dart';

part 'payment_repo.g.dart';

@riverpod
PaymentRepo paymentRepo(PaymentRepoRef ref) {
  final dioService = ref.watch(dioServiceProvider);
  return PaymentRepo(dioService);
}

class PaymentRepo {
  final DioService _dioService;

  PaymentRepo(this._dioService);

  Future<Either<ErrorResponse, String?>> initiatePayment(
      Map<String, dynamic> payload) async {
    try {
      final courseIds = payload["course_id"];

      final apiPayload = {
        "course_id": courseIds,
      };

      if (payload.containsKey("voucher_id")) {
        apiPayload["voucher_id"] = payload["voucher_id"];
      }

      print("Sending payload to enroll-course/paid/init: $apiPayload");

      final response =
          await _dioService.postRequest("/enroll-course/paid/init", apiPayload);

      print("Response from enroll-course/paid/init: ${response.data}");

      if (response.statusCode == 200) {
        final paymentUrl = response.data['data'];
        if (paymentUrl != null &&
            paymentUrl is String &&
            paymentUrl.isNotEmpty) {
          return Right(paymentUrl);
        } else if (response.data['success'] == true) {
          return const Right(null);
        } else {
          return Left(ErrorResponse(
            success: false,
            message: "Invalid payment URL received",
          ));
        }
      } else if (response.statusCode == 409) {
        return const Right(null);
      } else {
        return Left(ErrorResponse.fromJson(response.data));
      }
    } catch (e) {
      print("Payment error: $e");
      return Left(ErrorResponse(
        success: false,
        message: "Payment initialization failed: ${e.toString()}",
      ));
    }
  }

  Future<bool> enrollFreeCourse(payload) async {
    final response =
        await _dioService.postRequest("/enroll-course/free", payload);

    if (response.statusCode == 200) {
      return response.data['success'];
    } else {
      return response.data['success'];
    }
  }

  Future<Either<ErrorResponse, String?>> subscribe(
      Map<String, dynamic> payload) async {
    try {
      final apiPayload = {"requestedPlan": payload["requestedPlan"]};

      if (payload["isVoucherAdded"] == true && payload["voucher_id"] != null) {
        apiPayload["isVoucherAdded"] = true;
        apiPayload["voucher_id"] = payload["voucher_id"];
      }

      final response = await _dioService.postRequest(
          "/payment/subscription/init", apiPayload);

      if (response.statusCode == 200) {
        final paymentUrl = response.data['data'];
        if (paymentUrl != null &&
            paymentUrl is String &&
            paymentUrl.isNotEmpty) {
          return Right(paymentUrl);
        } else if (response.data['success'] == true) {
          return const Right(null);
        } else {
          return Left(ErrorResponse(
            success: false,
            message: "Invalid subscription URL received",
          ));
        }
      } else if (response.statusCode == 409) {
        return const Right(null);
      } else {
        return Left(ErrorResponse.fromJson(response.data));
      }
    } catch (e) {
      print("Subscription error: $e");
      return Left(ErrorResponse(
        success: false,
        message: "Subscription initialization failed: ${e.toString()}",
      ));
    }
  }

  /// `GET /subscription/plans` — the plans a student can subscribe to.
  Future<Either<ErrorResponse, List<SubscriptionPlan>>>
      getSubscriptionPlans() async {
    final response = await _dioService.getRequest("/subscription/plans");

    if (response.statusCode == 200) {
      final data = response.data['data'];
      if (data is! List) {
        return Left(ErrorResponse(
          success: false,
          message: "Unexpected subscription plans format",
        ));
      }
      return Right(data
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPlan.fromJson)
          .toList());
    } else {
      final errorResponse = ErrorResponse.fromJson(response.data);
      ErrorHandler().setErrorMessage(errorResponse.message);
      return Left(errorResponse);
    }
  }

  Future<Either<ErrorResponse, StudentProfile>> getStudentProfile() async {
    final response = await _dioService.getRequest("/user/profile");

    if (response.statusCode == 200) {
      return Right(StudentProfile.fromJson(response.data));
    } else {
      final errorResponse = ErrorResponse.fromJson(response.data);
      ErrorHandler().setErrorMessage(errorResponse.message);
      return Left(errorResponse);
    }
  }

  Future<bool> enrollSubscribedCourse(payload) async {
    final response =
        await _dioService.postRequest("/enroll-course/subscription", payload);

    if (response.statusCode == 200) {
      return response.data['success'];
    } else if (response.statusCode == 409) {
      return response.data["success"];
    } else {
      return response.data["success"];
    }
  }

// lib/features/payment/repository/payment_repo.dart - fixed getAllVouchers method

  Future<Either<ErrorResponse, List<VoucherModel>>> getAllVouchers(
      {String? courseId}) async {
    try {
      // Simplified params - only include isActive
      Map<String, dynamic> params = {'isActive': 'true'};

      final response = await _dioService.getRequest(
        "/voucher/all-voucher",
        queryParameters: params,
      );

      print("Voucher API response: ${response.data}");

      if (response.statusCode == 200) {
        // Handle different response formats with more detailed error handling
        try {
          List<VoucherModel> vouchers = [];

          if (response.data['data'] is List) {
            // Direct list format
            final dataList = response.data['data'] as List;
            vouchers =
                dataList.map((json) => VoucherModel.fromJson(json)).toList();
          } else if (response.data['data'] is Map) {
            // Nested data format with meta information
            if (response.data['data']['data'] is List) {
              final dataList = response.data['data']['data'] as List;
              vouchers =
                  dataList.map((json) => VoucherModel.fromJson(json)).toList();
            } else {
              print("Unexpected nested data format: ${response.data['data']}");
              return const Right([]);
            }
          } else {
            print("Unexpected data format: ${response.data['data']}");
            return const Right([]);
          }

          return Right(vouchers);
        } catch (parseError) {
          // Log detailed parsing error information to help debug
          print("Error parsing voucher data: $parseError");
          print("Response data structure: ${response.data.runtimeType}");
          print(
              "Data content sample: ${response.data.toString().substring(0, response.data.toString().length > 200 ? 200 : response.data.toString().length)}...");

          return Left(ErrorResponse(
            success: false,
            message: "Error parsing voucher data: $parseError",
          ));
        }
      } else {
        final errorResponse = ErrorResponse.fromJson(response.data);
        ErrorHandler().setErrorMessage(errorResponse.message);
        return Left(errorResponse);
      }
    } catch (e) {
      print("Error fetching vouchers: $e");
      return Left(ErrorResponse(
        success: false,
        message: e.toString(),
      ));
    }
  }
}
