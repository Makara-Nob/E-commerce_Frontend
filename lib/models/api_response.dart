class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    // Handle both boolean 'success' and string 'status'
    bool isSuccess = false;
    if (json['success'] is bool) {
      isSuccess = json['success'];
    } else if (json['status'] is String) {
      isSuccess = json['status'].toString().toLowerCase() == 'success';
    }

    return ApiResponse<T>(
      success: isSuccess,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson(Object? Function(T?)? toJsonT) {
    return {
      'success': success,
      'message': message,
      'data': data != null && toJsonT != null ? toJsonT(data) : data,
      'error': error,
    };
  }
}
