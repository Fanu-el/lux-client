import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../models/llm_model.dart';

class ChatApi {
  final Dio _dio = DioClient.instance.dio;

  // ── Chat sessions ──────────────────────────────────────────────────────────

  Future<Response> getChats() => _dio.get('/chats');

  Future<Response> createChat() =>
      _dio.post('/chats', data: {});

  Future<Response> getChat(String chatId) => _dio.get('/chats/$chatId');

  Future<Response> updateChat(String chatId, {required String title}) =>
      _dio.patch('/chats/$chatId', data: {'title': title});

  Future<Response> deleteChat(String chatId) => _dio.delete('/chats/$chatId');

  // ── Messages ───────────────────────────────────────────────────────────────

  Future<Response> getMessages(String chatId) =>
      _dio.get('/chats/$chatId/messages');

  /// Sends a user message and waits for the AI response.
  /// Requires the [model] header so the backend knows which LLM to use.
  Future<Response> sendMessage(
    String chatId, {
    required String content,
    required LlmModel model,
  }) =>
      _dio.post(
        '/chats/$chatId/messages',
        data: {'content': content},
        options: Options(headers: {'X-LLM-Model': model.id}),
      );
}
