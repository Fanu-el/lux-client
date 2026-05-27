import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../storage/token_storage.dart';

class DioClient {
  // ─── Singleton ──────────────────────────────────────────────────────────────
  static DioClient? _instance;
  static DioClient get instance => _instance ??= DioClient._internal();

  /// Set once at app start so the interceptor can force-logout when the
  /// refresh token is also expired / invalid.
  static Future<void> Function()? onForceLogout;

  // ─── Dio instance ────────────────────────────────────────────────────────────
  final Dio dio;

  DioClient._internal()
      : dio = Dio(
          BaseOptions(baseUrl: dotenv.env['API_BASE_URL']!),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        // ── Attach access token ──────────────────────────────────────────────
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },

        // ── Unwrap API envelope ──────────────────────────────────────────────
        onResponse: (response, handler) {
          final res = response.data;
          if (res is Map && res['is_error'] == true) {
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                error: res['error']?['message'] ?? 'Unknown error',
              ),
            );
          }
          // Return only the inner `data` field going forward
          if (res is Map && res.containsKey('data')) {
            response.data = res['data'];
          }
          return handler.next(response);
        },

        // ── Refresh on 401 / unwrap error envelope on other failures ─────────
        onError: (error, handler) async {
          // Always try to extract a human-readable message from the API
          // envelope first, regardless of status code.
          final unwrapped = _unwrapEnvelope(error);
          if (unwrapped != null) return handler.next(unwrapped);

          // Not a structured API error — handle connection-level failures.
          if (error.response == null) {
            return handler.next(_connectionError(error));
          }

          // For non-401 HTTP errors there's nothing more to do.
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          // 401 → attempt token refresh only if a session exists.
          final refreshToken = await TokenStorage.getRefreshToken();
          if (refreshToken == null) {
            // No session — plain auth failure (e.g. wrong credentials).
            // The envelope was already checked above; just pass through.
            return handler.next(error);
          }

          try {
            // Use a plain Dio (no interceptors) to avoid recursive 401 loops.
            final refreshDio = Dio(
              BaseOptions(baseUrl: dotenv.env['API_BASE_URL']!),
            );
            final res = await refreshDio.post(
              '/auth/refresh',
              data: {'refresh_token': refreshToken},
            );

            final newAccess =
                (res.data as Map)['data']?['access_token'] as String?;
            final newRefresh =
                (res.data as Map)['data']?['refresh_token'] as String?;
            if (newAccess == null) throw Exception('No token in refresh response');

            await TokenStorage.saveTokens(newAccess, newRefresh ?? refreshToken);

            // Retry the original request with the new token.
            error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
            final retry = await dio.fetch(error.requestOptions);
            return handler.resolve(retry);
          } catch (_) {
            await onForceLogout?.call();
          }

          return handler.next(error);
        },
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Extracts the backend's human-readable message from the API error envelope.
  /// Returns a new [DioException] with a String [error], or null if the
  /// response doesn't match the envelope format.
  static DioException? _unwrapEnvelope(DioException error) {
    final data = error.response?.data;
    if (data is! Map) return null;
    if (data['is_error'] != true) return null;

    final message = data['error']?['message'] as String? ?? 'Something went wrong.';
    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: message,
    );
  }

  /// Converts a connection-level failure into a friendly [DioException].
  static DioException _connectionError(DioException error) {
    final message = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Request timed out. Check your connection.',
      DioExceptionType.connectionError =>
        'Could not reach the server. Check your connection.',
      _ => 'Network error. Please try again.',
    };
    return DioException(
      requestOptions: error.requestOptions,
      type: error.type,
      error: message,
    );
  }
}
