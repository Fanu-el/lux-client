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
          // For non-401 errors, try to unwrap the API error envelope so screens
          // always receive the backend's human-readable message via error.error.
          if (error.response?.statusCode != 401) {
            final data = error.response?.data;
            if (data is Map && data['is_error'] == true) {
              final message =
                  data['error']?['message'] as String? ?? 'Unknown error';
              return handler.next(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  type: error.type,
                  error: message,
                ),
              );
            }
            return handler.next(error);
          }

          // 401 → attempt token refresh only if a session exists
          final refreshToken = await TokenStorage.getRefreshToken();
          if (refreshToken == null) {
            // No session — plain auth failure (e.g. wrong credentials on login).
            // Just pass the error through without triggering force-logout.
            return handler.next(error);
          }

          try {

            // Use a plain Dio (no interceptors) to avoid recursive 401 loops.
            // We also read the raw envelope manually here because this Dio
            // instance doesn't have the unwrapping interceptor attached.
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

            // Retry the original request with the new token
            error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
            final retry = await dio.fetch(error.requestOptions);
            return handler.resolve(retry);
          } catch (_) {
            // Refresh failed — delegate to AuthState which clears tokens
            // and notifies the router. We don't clear tokens here to avoid
            // a double-clear since logout() already does it.
            await onForceLogout?.call();
          }

          return handler.next(error);
        },
      ),
    );
  }
}
