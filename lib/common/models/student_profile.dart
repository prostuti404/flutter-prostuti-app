class StudentProfile {
  bool? success;
  String? message;
  Data? data;

  StudentProfile({this.success, this.message, this.data});

  StudentProfile.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
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

class Data {
  String? sId;
  String? userId;
  String? studentId;
  String? name;
  String? categoryType;
  String? mainCategory;
  String? subCategory;
  bool? isSubscribed;
  String? trialStartDate;

  String? phone;
  String? email;
  List<String>? enrolledCourses;
  String? subscriptionStartDate;
  String? subscriptionEndDate;
  String? createdAt;
  String? updatedAt;
  Image? image;

  Data(
      {this.sId,
      this.userId,
      this.studentId,
      this.name,
      this.categoryType,
      this.mainCategory,
      this.subCategory,
      this.isSubscribed,
      this.trialStartDate,
      this.phone,
      this.email,
      this.enrolledCourses,
      this.subscriptionStartDate,
      this.subscriptionEndDate,
      this.createdAt,
      this.updatedAt,
      this.image});

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['user_id'];
    // The backend docs call this `registeredId`; live payloads use `studentId`.
    studentId = (json['studentId'] ?? json['registeredId'])?.toString();
    name = json['name'];
    categoryType = json['categoryType'];
    final category = json['category'];
    if (category is Map<String, dynamic>) {
      mainCategory = category['mainCategory'];
      subCategory = category['subCategory'];
    }
    isSubscribed = json['isSubscribed'];
    trialStartDate = json['trialStartDate'];
    phone = json['phone'];
    email = json['email'];
    // Not part of the documented profile payload, so it may be absent.
    enrolledCourses =
        (json['enrolledCourses'] as List?)?.map((e) => e.toString()).toList();
    subscriptionStartDate = json['subscriptionStartDate'];
    subscriptionEndDate = json['subscriptionEndDate'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    image = json['image'] != null ? new Image.fromJson(json['image']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['user_id'] = userId;
    data['studentId'] = studentId;
    data['name'] = name;
    data['categoryType'] = categoryType;
    data['category'] = {
      'mainCategory': mainCategory,
      'subCategory': subCategory,
    };
    data['isSubscribed'] = isSubscribed;
    data['trialStartDate'] = trialStartDate;
    data['phone'] = phone;
    data['email'] = email;
    data['enrolledCourses'] = enrolledCourses;
    data['subscriptionStartDate'] = subscriptionStartDate;
    data['subscriptionEndDate'] = subscriptionEndDate;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    if (this.image != null) {
      data['image'] = this.image!.toJson();
    }
    return data;
  }
}

class Image {
  String? diskType;
  String? path;
  String? originalName;
  String? modifiedName;
  String? fileId;

  Image(
      {this.diskType,
      this.path,
      this.originalName,
      this.modifiedName,
      this.fileId});

  Image.fromJson(Map<String, dynamic> json) {
    diskType = json['diskType'];
    path = json['path'];
    originalName = json['originalName'];
    modifiedName = json['modifiedName'];
    fileId = json['fileId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['diskType'] = this.diskType;
    data['path'] = this.path;
    data['originalName'] = this.originalName;
    data['modifiedName'] = this.modifiedName;
    data['fileId'] = this.fileId;
    return data;
  }
}
