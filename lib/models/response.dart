import 'dart:io';

class Response {
  HttpStatus? httpStatus;
  dynamic data;
  String? message;
  int? statusCode;

  Response(this.httpStatus, this.data, this.message, this.statusCode);

  factory Response.fromJson(Map<String, dynamic> json) {
    final httpStatus = json['httpStatus'];
    final data = json['data'];
    final message = json['message'];
    final statusCode = json['statusCode'];
    return Response(httpStatus, data, message, statusCode);
  }
}
