class FlashcardDetailResponse {
  bool? success;
  String? message;
  FlashcardDetail? data;

  FlashcardDetailResponse({this.success, this.message, this.data});

  FlashcardDetailResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? FlashcardDetail.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class FlashcardDetail {
  String? sId;
  String? title;
  String? visibility;
  String? categoryId;
  FlashcardCategoryInfo? category;
  StudentInfo? studentId;
  bool? isApproved;
  String? createdAt;
  String? updatedAt;
  int? iV;
  List<FlashcardItem>? items;

  FlashcardDetail({
    this.sId,
    this.title,
    this.visibility,
    this.categoryId,
    this.category,
    this.studentId,
    this.isApproved,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.items,
  });

  FlashcardDetail.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    title = json['title'];
    visibility = json['visibility'];
    // The deck endpoint populates `categoryId` (and `studentId`) as objects;
    // older payloads carried plain id strings.
    final rawCategory = json['categoryId'];
    if (rawCategory is Map<String, dynamic>) {
      category = FlashcardCategoryInfo.fromJson(rawCategory);
      categoryId = category!.sId;
    } else if (rawCategory is String) {
      categoryId = rawCategory;
    }
    final rawStudent = json['studentId'];
    studentId = rawStudent is Map<String, dynamic>
        ? StudentInfo.fromJson(rawStudent)
        : null;
    isApproved = json['isApproved'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    if (json['items'] != null) {
      items = <FlashcardItem>[];
      json['items'].forEach((v) {
        items!.add(FlashcardItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['title'] = title;
    data['visibility'] = visibility;
    data['categoryId'] = category?.toJson() ?? categoryId;
    if (studentId != null) {
      data['studentId'] = studentId!.toJson();
    }
    data['isApproved'] = isApproved;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FlashcardCategoryInfo {
  String? sId;
  String? group;
  String? subject;
  String? lesson;
  String? name;

  FlashcardCategoryInfo(
      {this.sId, this.group, this.subject, this.lesson, this.name});

  FlashcardCategoryInfo.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    group = json['group'];
    subject = json['subject'];
    lesson = json['lesson'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['group'] = group;
    data['subject'] = subject;
    data['lesson'] = lesson;
    data['name'] = name;
    return data;
  }
}

class StudentInfo {
  String? sId;
  String? name;
  String? email;

  StudentInfo({this.sId, this.name, this.email});

  StudentInfo.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    data['email'] = email;
    return data;
  }
}

class FlashcardItem {
  String? sId;
  String? flashcardId;
  String? term;
  String? answer;
  int? viewCount;
  bool? isFavourite;
  bool? isKnown;
  bool? isLearned;

  FlashcardItem({
    this.sId,
    this.flashcardId,
    this.term,
    this.answer,
    this.viewCount,
    this.isFavourite,
    this.isKnown,
    this.isLearned,
  });

  FlashcardItem.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    flashcardId = json['flashcardId'];
    term = json['term'];
    answer = json['answer'];
    viewCount = json['viewCount'];
    isFavourite = json['isFavourite'];
    isKnown = json['isKnown'];
    isLearned = json['isLearned'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['flashcardId'] = flashcardId;
    data['term'] = term;
    data['answer'] = answer;
    data['viewCount'] = viewCount;
    data['isFavourite'] = isFavourite;
    data['isKnown'] = isKnown;
    data['isLearned'] = isLearned;
    return data;
  }
}
