import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prostuti/core/services/dio_service.dart';

part 'subject_repo.g.dart';

@riverpod
SubjectRepo subjectRepo(SubjectRepoRef ref) {
  final dioService = ref.watch(dioServiceProvider);
  return SubjectRepo(dioService);
}

class SubjectRepo {
  final DioService _dioService;

  SubjectRepo(this._dioService);

  Future<List<String>> fetchSubjects(String selectedStandard) async {
    const String endpoint = '/category/subject';
    final Map<String, String> params = {};

    if (selectedStandard == "Academic") {
      params['type'] = 'Academic';
    } else if (selectedStandard == "Engineering") {
      params['universityType'] = 'Engineering';
    } else if (selectedStandard == "University") {
      params['universityType'] = 'University';
    } else if (selectedStandard == "Medical") {
      params['universityType'] = 'Medical';
    }

    final response = await _dioService.getRequest(endpoint, queryParameters: params);

    if (response.statusCode == 200 && response.data['success'] == true) {
      return List<String>.from(response.data['data'] ?? []);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to load subjects');
    }
  }

  Future<List<String>> fetchChapters(String subjectName) async {
    const String endpoint = '/category/chapter';
    final response = await _dioService.getRequest(
      endpoint,
      queryParameters: {"subject": subjectName},
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      return List<String>.from(response.data['data'] ?? []);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to load chapters');
    }
  }
}
