import 'package:flutter_test/flutter_test.dart';
import 'package:prostuti/common/models/student_profile.dart';
import 'package:prostuti/features/flashcard/model/category_model.dart'
    as filter;
import 'package:prostuti/features/flashcard/model/flashcard_details_model.dart';
import 'package:prostuti/features/flashcard/model/flashcard_model.dart';
import 'package:prostuti/features/flashcard/viewmodel/flashcard_filter_viewmodel.dart';
import 'package:prostuti/features/notification/model/notification_model.dart';

/// Payloads copied from the backend integration guide (and live staging).
void main() {
  group('Category (Group -> Subject -> Lesson)', () {
    final live = {
      'success': true,
      'message': 'Categories are retrieved successfully',
      'meta': {'page': 1, 'limit': 2, 'count': 1},
      'data': [
        {
          '_id': '6af65ae13d5c441274972b34',
          'group': 'Science',
          'subject': 'Physics 1st',
          'lesson': 'Vector',
          'type': 'Academic',
          'name': 'Physics 1st - Vector',
        },
      ],
    };

    test('parses the live /category payload', () {
      final res = filter.CategoryResponse.fromJson(live);
      final c = res.data!.single;
      expect(c.group, 'Science');
      expect(c.subject, 'Physics 1st');
      expect(c.lesson, 'Vector');
      expect(c.displayName, 'Physics 1st - Vector');
      expect(res.meta!.count, 1);
    });

    test('displayName falls back to "subject - lesson"', () {
      final c = filter.Category(subject: 'Physics', lesson: 'Vector');
      expect(c.displayName, 'Physics - Vector');
    });

    test('FilterState emits the documented query params', () {
      final state = FilterState(
        selectedGroup: 'Science',
        selectedSubject: 'Physics',
        selectedLesson: 'Vector',
      );
      expect(state.toQueryParams(), {
        'categoryGroup': 'Science',
        'categorySubject': 'Physics',
        'categoryLesson': 'Vector',
      });
      expect(FilterState().toQueryParams(), isEmpty);
    });
  });

  group('Flashcard list', () {
    final deck = {
      '_id': '6710b12c4b001a1e89b30001',
      'title': 'HSC Physics: Vector Formulas',
      'visibility': 'EVERYONE',
      'isApproved': true,
      'studentId': {'_id': 's1', 'name': 'Rahim Ahmed'},
      'categoryId': {
        '_id': 'c1',
        'group': 'Science',
        'subject': 'Physics',
        'lesson': 'Vector',
        'name': 'Physics - Vector',
        'type': 'Academic',
      },
    };

    test('reads the live nested shape { data: { meta, data: [] } }', () {
      final res = FlashcardResponse.fromJson({
        'success': true,
        'data': {
          'meta': {'page': 1, 'limit': 5, 'count': 1},
          'data': [deck],
        },
      });
      expect(res.data!.meta!.count, 1);
      expect(res.data!.data!.single.categoryId!.group, 'Science');
    });

    test('also reads the documented flat shape { meta, data: [] }', () {
      final res = FlashcardResponse.fromJson({
        'success': true,
        'meta': {'page': 1, 'limit': 10, 'count': 15},
        'data': [deck],
      });
      expect(res.data!.meta!.count, 15);
      expect(res.data!.data!.single.title, 'HSC Physics: Vector Formulas');
    });

    test('an unpopulated categoryId string does not throw', () {
      final f = Flashcard.fromJson(
          {..._without(deck, 'categoryId'), 'categoryId': 'abc'});
      expect(f.categoryId, isNull);
    });
  });

  group('Flashcard deck details', () {
    test('accepts populated categoryId / studentId objects', () {
      final d = FlashcardDetail.fromJson({
        '_id': 'd1',
        'title': 'Deck',
        'categoryId': {
          '_id': 'c1',
          'group': 'Science',
          'subject': 'Physics',
          'lesson': 'Vector',
          'name': 'Physics - Vector',
        },
        'studentId': {'_id': 's1', 'name': 'Rahim', 'email': 'r@x.com'},
        'items': [
          {'_id': 'i1', 'term': 'Dot', 'answer': 'A.B'},
        ],
      });
      expect(d.categoryId, 'c1');
      expect(d.category!.name, 'Physics - Vector');
      expect(d.studentId!.name, 'Rahim');
      expect(d.items!.single.term, 'Dot');
    });

    test('still accepts a plain categoryId string', () {
      final d = FlashcardDetail.fromJson({'_id': 'd1', 'categoryId': 'c1'});
      expect(d.categoryId, 'c1');
      expect(d.category, isNull);
    });
  });

  group('Student profile', () {
    test('parses the documented payload (no enrolledCourses)', () {
      final p = StudentProfile.fromJson({
        'success': true,
        'data': {
          '_id': '66f3',
          'registeredId': 'SID1727341200abcde',
          'name': 'Tanvir Hasan',
          'phone': '01712345678',
          'categoryType': 'Academic',
          'category': {'mainCategory': 'Academic', 'subCategory': 'Science'},
          'isSubscribed': true,
          'subscriptionEndDate': '2026-12-31T23:59:59.000Z',
          'trialStartDate': '2026-09-01T00:00:00.000Z',
        },
      });
      expect(p.data!.studentId, 'SID1727341200abcde');
      expect(p.data!.subCategory, 'Science');
      expect(p.data!.isSubscribed, isTrue);
      expect(p.data!.enrolledCourses, isNull);
    });

    test('still reads the live `studentId` key and enrolledCourses', () {
      final p = StudentProfile.fromJson({
        'data': {
          'studentId': 'SID1',
          'enrolledCourses': ['a', 'b'],
        },
      });
      expect(p.data!.studentId, 'SID1');
      expect(p.data!.enrolledCourses, ['a', 'b']);
    });
  });

  group('Notifications', () {
    test('parses the documented notification', () {
      final n = NotificationModel.fromJson({
        'success': true,
        'data': [
          {
            '_id': 'n1',
            'student_id': 's1',
            'title': 'Course Subscription',
            'message': 'Subscribed',
            'isRead': false,
            'createdAt': '2026-10-12T14:00:00.000Z',
          },
        ],
      });
      expect(n.data!.single.isRead, isFalse);
      expect(n.data!.single.studentId, 's1');
    });
  });
}

Map<String, dynamic> _without(Map<String, dynamic> m, String key) =>
    Map.of(m)..remove(key);
