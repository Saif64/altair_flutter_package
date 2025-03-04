// lib/src/altair_client.dart
import 'package:dio/dio.dart';

import '../interceptors/auth_interceptor.dart';
import '../interceptors/cache_interceptor.dart';
import '../models/altair_config.dart';
import '../models/altair_response.dart';
import '../models/auth_tokens.dart';
import '../storage/token_storage.dart';

class Altair {
  final AltairConfig config;
  final Dio _dio;
  final TokenStorage _tokenStorage;
  late AuthInterceptor _authInterceptor;
  late CacheInterceptor _cacheInterceptor;

  /// Creates a new AltairClient instance
  ///
  /// [config] is required and contains all configuration for the client
  /// [dio] is optional and can be provided for custom dio setup
  /// [tokenStorage] is optional and defaults to SecureTokenStorage
  Altair({required this.config, Dio? dio, TokenStorage? tokenStorage})
    : _dio = dio ?? Dio(),
      _tokenStorage = tokenStorage ?? SecureTokenStorage() {
    _init();
  }

  void _init() {
    // Configure base Dio instance
    _dio.options = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: Duration(milliseconds: config.connectTimeout),
      receiveTimeout: Duration(milliseconds: config.receiveTimeout),
      sendTimeout: Duration(milliseconds: config.sendTimeout),
      headers: config.defaultHeaders,
      queryParameters: config.defaultQueryParams,
    );

    // Add interceptors
    _cacheInterceptor = CacheInterceptor(config);
    _authInterceptor = AuthInterceptor(_dio, _tokenStorage, config);

    if (config.enableCache) {
      _dio.interceptors.add(_cacheInterceptor);
    }

    if (config.autoAuthenticate) {
      _dio.interceptors.add(_authInterceptor);
    }
  }

  /// Login with username/email and password
  ///
  /// Returns AuthTokens if successful
  Future<AltairResponse<AuthTokens>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        config.accessTokenPath,
        data: {'username': username, 'password': password},
      );

      final tokens = AuthTokens.fromJson(response.data);
      await _tokenStorage.saveTokens(tokens);

      return AltairResponse.success(
        data: tokens,
        statusCode: response.statusCode,
        message: 'Login successful',
      );
    } on DioException catch (e) {
      return AltairResponse.error(
        statusCode: e.response?.statusCode,
        message: e.response?.data?['message'] ?? 'Login failed',
      );
    } catch (e) {
      return AltairResponse.error(message: 'Login failed: $e');
    }
  }

  /// Logout the current user
  ///
  /// Clears the stored tokens
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  /// Refreshes the authentication tokens
  ///
  /// Returns new AuthTokens if successful
  Future<AltairResponse<AuthTokens>> refreshToken() async {
    try {
      final currentTokens = await _tokenStorage.getTokens();
      if (currentTokens == null) {
        return AltairResponse.error(message: 'No refresh token available');
      }

      final response = await _dio.post(
        config.refreshTokenPath,
        data: {'refresh_token': currentTokens.refreshToken},
        options: Options(
          headers: {'Authorization': 'Bearer ${currentTokens.refreshToken}'},
        ),
      );

      final newTokens = AuthTokens.fromJson(response.data);
      await _tokenStorage.saveTokens(newTokens);

      return AltairResponse.success(
        data: newTokens,
        statusCode: response.statusCode,
        message: 'Token refreshed successfully',
      );
    } on DioException catch (e) {
      return AltairResponse.error(
        statusCode: e.response?.statusCode,
        message: e.response?.data?['message'] ?? 'Token refresh failed',
      );
    } catch (e) {
      return AltairResponse.error(message: 'Token refresh failed: $e');
    }
  }

  /// Get the current authentication tokens
  Future<AuthTokens?> getTokens() async {
    return await _tokenStorage.getTokens();
  }

  /// Check if the user is authenticated
  Future<bool> isAuthenticated() async {
    final tokens = await _tokenStorage.getTokens();
    return tokens != null && !tokens.isAccessTokenExpired;
  }

  /// Perform a GET request
  Future<AltairResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
    T Function(dynamic)? converter,
  }) async {
    return _request<T>(
      'GET',
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      converter: converter,
    );
  }

  /// Perform a POST request
  Future<AltairResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    T Function(dynamic)? converter,
  }) async {
    return _request<T>(
      'POST',
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      converter: converter,
    );
  }

  /// Perform a PUT request
  Future<AltairResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    T Function(dynamic)? converter,
  }) async {
    return _request<T>(
      'PUT',
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      converter: converter,
    );
  }

  /// Perform a PATCH request
  Future<AltairResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    T Function(dynamic)? converter,
  }) async {
    return _request<T>(
      'PATCH',
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      converter: converter,
    );
  }

  /// Perform a DELETE request
  Future<AltairResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? converter,
  }) async {
    return _request<T>(
      'DELETE',
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      converter: converter,
    );
  }

  /// Generic request method that handles all request types
  Future<AltairResponse<T>> _request<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    T Function(dynamic)? converter,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: options?.headers,
          responseType: options?.responseType,
          contentType: options?.contentType,
          validateStatus: options?.validateStatus,
          receiveTimeout: options?.receiveTimeout,
          sendTimeout: options?.sendTimeout,
          extra: options?.extra,
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      final fromCache =
          response.headers['x-altair-cache']?.first == 'hit' ||
          response.headers['x-altair-cache']?.first == 'stale';

      dynamic responseData = response.data;
      if (converter != null) {
        responseData = converter(responseData);
      }

      return AltairResponse.success(
        data: responseData,
        statusCode: response.statusCode,
        headers: response.headers.map,
        fromCache: fromCache,
      );
    } on DioException catch (e) {
      return AltairResponse.error(
        statusCode: e.response?.statusCode,
        message: e.response?.data?['message'] ?? e.message,
        headers: e.response?.headers.map,
      );
    } catch (e) {
      return AltairResponse.error(message: e.toString());
    }
  }

  /// Clear the cache
  Future<void> clearCache() async {
    if (config.enableCache) {
      await _cacheInterceptor.clearCache();
    }
  }

  /// Get the underlying Dio instance for advanced usage
  Dio get dio => _dio;
}
