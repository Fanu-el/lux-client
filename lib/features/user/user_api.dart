import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';

class UserApi {
  final Dio _dio = DioClient.instance.dio;

  Future<Response> updateProfile({required String name}) =>
      _dio.patch('/users/update-profile', data: {'name': name});
}
