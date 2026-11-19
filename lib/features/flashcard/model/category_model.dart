/// A category in the unified Group -> Subject -> Lesson schema.
///
/// `name` is the display string "subject - lesson". `type` is "Academic"
/// (default) or "Admission".
class Category {
  final String? sId;
  final String? group;
  final String? subject;
  final String? lesson;
  final String? name;
  final String? type;
  final String? createdAt;
  final String? updatedAt;

  Category({
    this.sId,
    this.group,
    this.subject,
    this.lesson,
    this.name,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  /// Display label, falling back to "subject - lesson" when `name` is absent.
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    return [subject, lesson].where((e) => e != null && e.isNotEmpty).join(' - ');
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      sId: json['_id'],
      group: json['group'],
      subject: json['subject'],
      lesson: json['lesson'],
      name: json['name'],
      type: json['type'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'group': group,
      'subject': subject,
      'lesson': lesson,
      'name': name,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class CategoryResponse {
  final bool? success;
  final String? message;
  final CategoryMeta? meta;
  final List<Category>? data;

  CategoryResponse({
    this.success,
    this.message,
    this.meta,
    this.data,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      success: json['success'],
      message: json['message'],
      meta: json['meta'] != null ? CategoryMeta.fromJson(json['meta']) : null,
      data: json['data'] != null
          ? List<Category>.from(json['data'].map((x) => Category.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'meta': meta?.toJson(),
      'data': data?.map((x) => x.toJson()).toList(),
    };
  }
}

class CategoryMeta {
  final int? page;
  final int? limit;
  final int? count;

  CategoryMeta({
    this.page,
    this.limit,
    this.count,
  });

  factory CategoryMeta.fromJson(Map<String, dynamic> json) {
    return CategoryMeta(
      page: json['page'],
      limit: json['limit'],
      count: json['count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'count': count,
    };
  }
}
