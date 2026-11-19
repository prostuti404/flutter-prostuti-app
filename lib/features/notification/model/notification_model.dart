class NotificationModel {
  bool? success;
  String? message;
  List<Data>? data;

  NotificationModel({this.success, this.message, this.data});

  NotificationModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? sId;
  String? studentId;
  String? title;
  String? message;
  bool? isRead;
  String? createdAt;
  String? updatedAt;

  Data(
      {this.sId,
        this.studentId,
        this.title,
        this.message,
        this.isRead,
        this.createdAt,
        this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    studentId = json['student_id'] is String ? json['student_id'] : null;
    title = json['title'];
    message = json['message'];
    isRead = json['isRead'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['student_id'] = this.studentId;
    data['title'] = this.title;
    data['message'] = this.message;
    data['isRead'] = this.isRead;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
