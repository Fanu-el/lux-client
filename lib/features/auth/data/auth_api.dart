import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class AuthApi {
  final Dio _dio = DioClient.instance.dio;

  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);

  Future<Response> login(Map<String, dynamic> data) =>
      _dio.post('/auth/login', data: data);

  Future<Response> verifyEmail(Map<String, dynamic> data) =>
      _dio.post('/auth/verify-email', data: data);

  Future<Response> resendCode(String email) =>
      _dio.post('/auth/resend-verification-code', data: {'email': email});

  Future<Response> forgotPassword(String email) =>
      _dio.post('/auth/forgot-password', data: {'email': email});

  Future<Response> resetPassword(Map<String, dynamic> data) =>
      _dio.post('/auth/reset-password', data: data);

  Future<Response> getMe() => _dio.get('/auth/me');
}