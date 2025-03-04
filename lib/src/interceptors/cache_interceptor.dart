import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/altair_config.dart';

class CachedResponse {
  final Response response;
  final DateTime timestamp;
  final DateTime expiresAt;

  CachedResponse({
    required this.response,
    required this.timestamp,
    required this.expiresAt,
  });

  factory CachedResponse.fromJson(Map<String, dynamic> json) {
    return CachedResponse(
      response: Response(
        data: json['data'],
        headers: Headers.fromMap(
          Map<String, List<String>>.from(json['headers']),
        ),
        requestOptions: RequestOptions(path: ''),
        statusCode: json['statusCode'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': response.data,
      'headers': response.headers.map,
      'statusCode': response.statusCode,
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class CacheInterceptor extends Interceptor {
  late Box<Map> _cacheBox;
  final AltairConfig _config;
  bool _initialized = false;

  CacheInterceptor(this._config) {
    _initCache();
  }

  Future<void> _initCache() async {
    if (!_initialized) {
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init('${appDir.path}/altair_cache');
      _cacheBox = await Hive.openBox<Map>('altair_cache');
      _initialized = true;
    }
  }

  String _getCacheKey(RequestOptions options) {
    final String requestUrl = options.uri.toString();
    final String method = options.method;
    final String? requestData =
        options.data != null ? jsonEncode(options.data) : null;

    final String rawKey = '$method-$requestUrl-${requestData ?? ''}';
    return md5.convert(utf8.encode(rawKey)).toString();
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip caching for non-GET requests or if caching is disabled
    if (!_config.enableCache || options.method != 'GET') {
      return handler.next(options);
    }

    await _initCache();
    final cacheKey = _getCacheKey(options);
    final cachedData = _cacheBox.get(cacheKey);

    if (cachedData != null) {
      try {
        final cachedResponse = CachedResponse.fromJson(
          Map<String, dynamic>.from(cachedData),
        );

        if (!cachedResponse.isExpired) {
          // Valid cache, use it
          cachedResponse.response.headers.set('x-altair-cache', 'hit');
          return handler.resolve(cachedResponse.response);
        } else if (_config.useStaleWhileRevalidate) {
          // Stale cache, use it but also fetch fresh data
          cachedResponse.response.headers.set('x-altair-cache', 'stale');
          handler.resolve(cachedResponse.response);

          // Send a separate request to update the cache
          _fetchAndCacheResponse(options, cacheKey);
          return;
        }
      } catch (e) {
        // Invalid cache, remove it
        _cacheBox.delete(cacheKey);
      }
    }

    // No cache or expired without stale-while-revalidate
    handler.next(options);
  }

  void _fetchAndCacheResponse(RequestOptions options, String cacheKey) async {
    try {
      final dio = Dio(
        BaseOptions(baseUrl: options.baseUrl, headers: options.headers),
      );

      dio.interceptors.clear(); // Prevent infinite loops

      final response = await dio.request(
        options.path,
        data: options.data,
        queryParameters: options.queryParameters,
        options: Options(method: options.method),
      );

      _saveResponseToCache(response, cacheKey);
    } catch (e) {
      // Silently fail on background fetch
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (!_config.enableCache || response.requestOptions.method != 'GET') {
      return handler.next(response);
    }

    await _initCache();
    final cacheKey = _getCacheKey(response.requestOptions);

    // Only cache successful responses
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      _saveResponseToCache(response, cacheKey);
    }

    // Add cache header if not already set
    if (!response.headers.map.containsKey('x-altair-cache')) {
      response.headers.set('x-altair-cache', 'miss');
    }

    handler.next(response);
  }

  void _saveResponseToCache(Response response, String cacheKey) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(seconds: _config.cacheTtl));

    final cachedResponse = CachedResponse(
      response: response,
      timestamp: now,
      expiresAt: expiresAt,
    );

    await _cacheBox.put(cacheKey, cachedResponse.toJson());
  }

  Future<void> clearCache() async {
    await _initCache();
    await _cacheBox.clear();
  }
}
