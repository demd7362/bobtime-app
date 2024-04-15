import 'dart:convert';

import 'package:http/http.dart' as http;

bool is2XXSuccessful(dynamic response) {
  return response != null &&
      (response['statusCode'] == 200 || response['statusCode'] == 201);
}

class ApiService {
  static const String baseUrl = 'http://144.24.74.58:4070';

  static Future<dynamic> get(String endpoint) async {
    print('your request uri -> $baseUrl$endpoint');
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, {dynamic body}) async {
    print('your request uri -> $baseUrl$endpoint');
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> patch(String endpoint, {dynamic body}) async {
    print('your request uri -> $baseUrl$endpoint');
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    print('your request uri -> $baseUrl$endpoint');
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'));
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    final result = jsonDecode(response.body);
    print('response -> $result');
    return result;
  }
}

// 사용자 정의 예외 클래스
class ApiException implements Exception {
  final String message;
  final String prefix;

  ApiException(this.message, this.prefix);

  @override
  String toString() {
    return "$prefix$message";
  }
}

class FetchDataException extends ApiException {
  FetchDataException(String message)
      : super(message, "Error During Communication: ");
}

class BadRequestException extends ApiException {
  BadRequestException(String message) : super(message, "Invalid Request: ");
}

class UnauthorisedException extends ApiException {
  UnauthorisedException(String message) : super(message, "Unauthorised: ");
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, "Not Found: ");
}
