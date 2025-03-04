import 'package:dio/dio.dart';

class AltairConfig {
  /// Base URL for all API requests
  final String baseUrl;

  /// URL path for refreshing tokens (appended to baseUrl)
  final String refreshTokenPath;

  /// URL path for obtaining access tokens (appended to baseUrl)
  final String accessTokenPath;

  /// Default headers to include in all requests
  final Map<String, dynamic>? defaultHeaders;

  /// Default query parameters to include in all requests
  final Map<String, dynamic>? defaultQueryParams;

  /// Connect timeout in milliseconds
  final int connectTimeout;

  /// Receive timeout in milliseconds
  final int receiveTimeout;

  /// Send timeout in milliseconds
  final int sendTimeout;

  /// Whether to enable caching
  final bool enableCache;

  /// Default cache TTL in seconds
  final int cacheTtl;

  /// Whether to use stale-while-revalidate caching strategy
  final bool useStaleWhileRevalidate;

  /// Whether to automatically handle authentication
  final bool autoAuthenticate;

  /// Custom configuration for the Dio instance
  final BaseOptions? dioOptions;

  AltairConfig({
    required this.baseUrl,
    this.refreshTokenPath = '/auth/refresh',
    this.accessTokenPath = '/auth/token',
    this.defaultHeaders,
    this.defaultQueryParams,
    this.connectTimeout = 30000,
    this.receiveTimeout = 30000,
    this.sendTimeout = 30000,
    this.enableCache = true,
    this.cacheTtl = 300, // 5 minutes
    this.useStaleWhileRevalidate = true,
    this.autoAuthenticate = true,
    this.dioOptions,
  });
}
