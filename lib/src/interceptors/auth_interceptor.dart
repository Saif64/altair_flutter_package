import 'package:dio/dio.dart';

import '../models/altair_config.dart';
import '../models/auth_tokens.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final AltairConfig _config;
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  AuthInterceptor(this._dio, this._tokenStorage, this._config);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for token endpoints
    if (options.path == _config.accessTokenPath ||
        options.path == _config.refreshTokenPath) {
      return handler.next(options);
    }

    // Add auth header if needed
    if (_config.autoAuthenticate) {
      final tokens = await _tokenStorage.getTokens();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && _config.autoAuthenticate) {
      final tokens = await _tokenStorage.getTokens();

      // No tokens or refresh token expired, let the error pass through
      if (tokens == null || tokens.isRefreshTokenExpired) {
        return handler.next(err);
      }

      // Store the failed request to retry later
      _pendingRequests.add(err.requestOptions);

      // Try to refresh the token if not already refreshing
      if (!_isRefreshing) {
        _isRefreshing = true;

        try {
          final newTokens = await _refreshToken(tokens.refreshToken);
          await _tokenStorage.saveTokens(newTokens);

          // Retry all pending requests with the new token
          for (final pendingRequest in _pendingRequests) {
            final retryDio = Dio();
            pendingRequest.headers['Authorization'] =
                'Bearer ${newTokens.accessToken}';

            final response = await retryDio.fetch(pendingRequest);
            if (pendingRequest == err.requestOptions) {
              handler.resolve(response);
            }
          }
        } catch (e) {
          // If refresh fails, clear tokens and let the error pass through
          await _tokenStorage.clearTokens();
          handler.next(err);
        } finally {
          _pendingRequests.clear();
          _isRefreshing = false;
        }
      } else {
        // If already refreshing, just wait for it to complete
        // The request will be retried in the first refreshing block
      }
    } else {
      // For other errors, just pass through
      handler.next(err);
    }
  }

  Future<AuthTokens> _refreshToken(String refreshToken) async {
    final response = await _dio.post(
      _config.refreshTokenPath,
      data: {'refresh_token': refreshToken},
      options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
    );

    return AuthTokens.fromJson(response.data);
  }
}
