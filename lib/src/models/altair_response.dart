class AltairResponse<T> {
  final T? data;
  final int? statusCode;
  final String? message;
  final bool success;
  final Map<String, dynamic>? headers;
  final bool fromCache;

  AltairResponse({
    this.data,
    this.statusCode,
    this.message,
    this.success = true,
    this.headers,
    this.fromCache = false,
  });

  factory AltairResponse.success({
    T? data,
    int? statusCode,
    String? message,
    Map<String, dynamic>? headers,
    bool fromCache = false,
  }) {
    return AltairResponse(
      data: data,
      statusCode: statusCode,
      message: message,
      success: true,
      headers: headers,
      fromCache: fromCache,
    );
  }

  factory AltairResponse.error({
    T? data,
    int? statusCode,
    String? message,
    Map<String, dynamic>? headers,
  }) {
    return AltairResponse(
      data: data,
      statusCode: statusCode,
      message: message,
      success: false,
      headers: headers,
    );
  }
}
