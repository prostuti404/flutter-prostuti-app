// Update profile_repo.dart
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prostuti/core/services/dio_service.dart';
import 'package:prostuti/core/services/error_handler.dart';
import 'package:prostuti/core/services/error_response.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../common/models/student_profile.dart';

part 'profile_repo.g.dart';

@riverpod
ProfileRepo profileRepo(ProfileRepoRef ref) {
  final dioService = ref.watch(dioServiceProvider);
  return ProfileRepo(dioService);
}

class ProfileRepo {
  final DioService _dioService;

  ProfileRepo(this._dioService);

  /// Permanently deletes the signed-in student's account
  /// (`DELETE /student/delete-account`, no body). Required for store policies.
  Future<Either<ErrorResponse, bool>> deleteAccount() async {
    try {
      final response = await _dioService.deleteRequest("/student/delete-account");

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

  Future<Either<ErrorResponse, bool>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final payload = {
        "oldPassword": oldPassword,
        "newPassword": newPassword,
        "confirmPassword": confirmPassword,
      };

      final response =
          await _dioService.postRequest("/auth/change-password", payload);

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        final errorResponse = ErrorResponse.fromJson(response.data);
        ErrorHandler().setErrorMessage(errorResponse.message);
        return Left(errorResponse);
      }
    } catch (e) {
      final errorResponse = ErrorResponse(
        message: e.toString(),
        success: e.toString() == 'true',
      );
      ErrorHandler().setErrorMessage(errorResponse.message);
      return Left(errorResponse);
    }
  }

  Future<Either<ErrorResponse, bool>> updateProfile({
    String? name,
    XFile? image,
    required String studentId,
  }) async {
    try {
      debugPrint("Updating profile for student ID: $studentId");
      debugPrint("Name to update: $name");
      debugPrint("Image to update: ${image?.name}");

      // Create form data
      FormData formData = FormData();

      // IMPORTANT FIX: Always include name in profileData
      // Get the current user profile to include current name if not changing
      final userProfile = await _getCurrentUserProfile(studentId);

      final Map<String, dynamic> profileData = {};

      // If name is provided, use it, otherwise use current name from profile
      if (name != null) {
        profileData['name'] = name;
      } else if (userProfile != null && image != null) {
        // Only if we're updating the image but not the name
        profileData['name'] = userProfile.data?.name ?? '';
      }

      // Convert to JSON string and add to form
      final jsonString = jsonEncode(profileData);
      debugPrint("Profile data JSON: $jsonString");

      // Always include profileData
      formData.fields.add(
        MapEntry('profileData', jsonString),
      );

      // Add image if provided
      if (image != null) {
        try {
          final bytes = await image.readAsBytes();

          // Get file extension for mime type
          final fileExt = image.path.split('.').last.toLowerCase();
          String mimeType = 'image/jpeg';
          if (fileExt == 'png') {
            mimeType = 'image/png';
          } else if (fileExt == 'jpg' || fileExt == 'jpeg') {
            mimeType = 'image/jpeg';
          }

          debugPrint("Creating MultipartFile with mime type: $mimeType");

          final multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: image.name,
            contentType: MediaType.parse(mimeType),
          );

          formData.files.add(MapEntry('avatar', multipartFile));
          debugPrint("Added image to form data: ${image.name}");
        } catch (e) {
          debugPrint("Error preparing image: ${e.toString()}");
        }
      }

      // Make the request
      debugPrint("Sending PATCH request to /student/profile/$studentId");
      final response = await _dioService.patchRequest(
        "/student/profile/$studentId",
        data: formData,
      );

      debugPrint("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        final errorResponse = ErrorResponse.fromJson(response.data);
        ErrorHandler().setErrorMessage(errorResponse.message);
        return Left(errorResponse);
      }
    } catch (e) {
      debugPrint("Error in updateProfile: ${e.toString()}");
      final errorResponse = ErrorResponse(
        message: e.toString(),
        success: false,
      );
      ErrorHandler().setErrorMessage(errorResponse.message);
      return Left(errorResponse);
    }
  }

// Helper method to get current user profile
  Future<StudentProfile?> _getCurrentUserProfile(String studentId) async {
    try {
      final response = await _dioService.getRequest("/user/profile");
      if (response.statusCode == 200) {
        return StudentProfile.fromJson(response.data);
      }
    } catch (e) {
      debugPrint("Error fetching current profile: ${e.toString()}");
    }
    return null;
  }
}
