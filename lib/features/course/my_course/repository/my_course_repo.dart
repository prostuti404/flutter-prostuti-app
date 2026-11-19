// __brick__/repository/my_course_repo.dart
import 'package:dartz/dartz.dart';
import 'package:prostuti/core/services/dio_service.dart';
import 'package:prostuti/core/services/error_response.dart';
import 'package:prostuti/features/course/my_course/model/my_course_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/error_handler.dart';
import '../../course_details/model/course_details_model.dart';
import '../model/course_progress_model.dart';

part 'my_course_repo.g.dart';

@riverpod
MyCourseRepo myCourseRepo(MyCourseRepoRef ref) {
  final dioService = ref.watch(dioServiceProvider);
  return MyCourseRepo(dioService);
}

class MyCourseRepo {
  final DioService _dioService;

  MyCourseRepo(this._dioService);

  Future<Either<ErrorResponse, EnrolledCourseList>>
      getEnrolledCourseList() async {
    final response = await _dioService.getRequest("/enroll-course?limit=0");

    if (response.statusCode == 200) {
      return Right(EnrolledCourseList.fromJson(response.data));
    } else {
      final errorResponse = ErrorResponse.fromJson(response.data);
      ErrorHandler().setErrorMessage(errorResponse.message);
      return Left(errorResponse);
    }
  }

  Future<List<CourseProgress>> courseProgress() async {
    final response =
        await _dioService.getRequest("/progress/all-course-progress");

    if (response.statusCode == 200) {
      final List<dynamic> courseData = response.data['data'];

      final List<CourseProgress> progressList =
          courseData.map((item) => CourseProgress.fromJson(item)).toList();

      return progressList;
    } else {
      throw Exception(
          "Failed to load course progress: ${response.data['message']}");
    }
  }

  // Add this method to the MyCourseRepo class

  Future<CourseDetails> getCourseDetails(String courseId) async {
    final response = await _dioService.getRequest("/course/preview/$courseId");

    if (response.statusCode == 200) {
      return CourseDetails.fromJson(response.data);
    } else {
      throw Exception(
          "Failed to load course details: ${response.data['message']}");
    }
  }
}
