class QuestionPatternModel {
  bool? success;
  String? message;
  QuestionPatternDataWrapper? data;

  QuestionPatternModel({this.success, this.message, this.data});

  factory QuestionPatternModel.fromJson(Map<String, dynamic> json) {
    return QuestionPatternModel(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? QuestionPatternDataWrapper.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data?.toJson(),
  };
}

class QuestionPatternDataWrapper {
  Meta? meta;
  List<QuestionPattern>? data;

  QuestionPatternDataWrapper({this.meta, this.data});

  factory QuestionPatternDataWrapper.fromJson(Map<String, dynamic> json) {
    return QuestionPatternDataWrapper(
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
      data: json['data'] != null
          ? List<QuestionPattern>.from(
          json['data'].map((x) => QuestionPattern.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'meta': meta?.toJson(),
    'data': data?.map((e) => e.toJson()).toList(),
  };
}

class Meta {
  int? page;
  int? limit;
  int? count;

  Meta({this.page, this.limit, this.count});

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
    page: json['page'],
    limit: json['limit'],
    count: json['count'],
  );

  Map<String, dynamic> toJson() => {
    'page': page,
    'limit': limit,
    'count': count,
  };
}

class QuestionPattern {
  String? id;
  List<CategoryId>? categoryId;
  int? time;
  String? questionType;
  List<Subject>? mainSubjects;
  List<Subject>? optionalSubjects;
  CreatedBy? createdBy;
  String? updatedBy;
  String? createdAt;
  String? updatedAt;
  int? v;

  QuestionPattern({
    this.id,
    this.categoryId,
    this.time,
    this.questionType,
    this.mainSubjects,
    this.optionalSubjects,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory QuestionPattern.fromJson(Map<String, dynamic> json) {
    return QuestionPattern(
      id: json['_id'],
      categoryId: json['category_id'] != null
          ? List<CategoryId>.from(
          json['category_id'].map((x) => CategoryId.fromJson(x)))
          : [],
      time: json['time'],
      questionType: json['questionType'],
      mainSubjects: json['mainSubjects'] != null
          ? List<Subject>.from(
          json['mainSubjects'].map((x) => Subject.fromJson(x)))
          : [],
      optionalSubjects: json['optionalSubjects'] != null
          ? List<Subject>.from(
          json['optionalSubjects'].map((x) => Subject.fromJson(x)))
          : [],
      createdBy: json['createdBy'] != null
          ? CreatedBy.fromJson(json['createdBy'])
          : null,
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'category_id': categoryId?.map((x) => x.toJson()).toList(),
    'time': time,
    'questionType': questionType,
    'mainSubjects': mainSubjects?.map((x) => x.toJson()).toList(),
    'optionalSubjects': optionalSubjects?.map((x) => x.toJson()).toList(),
    'createdBy': createdBy?.toJson(),
    'updatedBy': updatedBy,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
  };
}

class CategoryId {
  String? id;
  String? type;
  String? group;
  String? division;
  String? subject;
  String? chapter;
  String? lesson;
  String? createdAt;
  String? updatedAt;
  int? v;

  CategoryId({
    this.id,
    this.type,
    this.group,
    this.division,
    this.subject,
    this.chapter,
    this.lesson,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory CategoryId.fromJson(Map<String, dynamic> json) => CategoryId(
    id: json['_id'],
    type: json['type'],
    group: json['group'],
    division: json['division'],
    subject: json['subject'],
    chapter: json['chapter'],
    lesson: json['lesson'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
    v: json['__v'],
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'type': type,
    'group': group,
    'division': division,
    'subject': subject,
    'chapter': chapter,
    'lesson': lesson,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
  };
}

class Subject {
  String? subject;
  int? questionCount;
  String? id;

  Subject({this.subject, this.questionCount, this.id});

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    subject: json['subject'],
    questionCount: json['questionCount'],
    id: json['_id'],
  );

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'questionCount': questionCount,
    '_id': id,
  };
}

class CreatedBy {
  String? id;
  String? userId;
  String? adminId;
  String? email;
  String? createdAt;
  String? updatedAt;

  CreatedBy({
    this.id,
    this.userId,
    this.adminId,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) => CreatedBy(
    id: json['_id'],
    userId: json['user_id'],
    adminId: json['adminId'],
    email: json['email'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'user_id': userId,
    'adminId': adminId,
    'email': email,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
