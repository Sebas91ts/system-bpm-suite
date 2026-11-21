import 'dart:convert';

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final T data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) dataParser,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: (json['message'] as String?)?.trim().isNotEmpty == true
          ? (json['message'] as String).trim()
          : '',
      data: dataParser(json['data']),
    );
  }

  static Map<String, dynamic> decodeBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const FormatException('Invalid API response body.');
  }
}
