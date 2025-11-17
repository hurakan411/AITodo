import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/proposal.dart';
import '../models/profile.dart';

class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<TaskProposal> propose(String text) async {
    try {
      final res = await _dio.post('/tasks/propose', data: {'text': text});
      return TaskProposal.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // バリデーションエラー時、バックエンドのメッセージをそのまま投げる
        final message = e.response?.data['detail'] ?? '提案取得に失敗しました';
        throw Exception(message);
      }
      rethrow;
    }
  }

  Future<Task> accept(TaskProposal proposal) async {
    final res = await _dio.post('/tasks/accept', data: proposal.toJson());
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Task> extend(int extraMinutes) async {
    final res = await _dio.post('/tasks/extend', data: {'extra_minutes': extraMinutes});
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Task> complete(String selfReport) async {
    final res = await _dio.post('/tasks/complete', data: {'self_report': selfReport});
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Task> withdraw() async {
    final res = await _dio.post('/tasks/withdraw');
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Task?> currentTask() async {
    final res = await _dio.get('/tasks/current');
    if (res.data == null) return null;
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<StatusPayload> status() async {
    final res = await _dio.get('/status');
    return StatusPayload.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> gameoverAck() async {
    await _dio.post('/gameover/ack');
  }
}

class StatusPayload {
  final Profile profile;
  final Task? currentTask;
  final List<Task> recentTasks;
  final int nextThreshold;
  final String aiLine;
  final bool gameOver;

  StatusPayload({
    required this.profile,
    required this.currentTask,
    required this.recentTasks,
    required this.nextThreshold,
    required this.aiLine,
    required this.gameOver,
  });

  factory StatusPayload.fromJson(Map<String, dynamic> json) => StatusPayload(
        profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
        currentTask: json['current_task'] == null
            ? null
            : Task.fromJson(json['current_task'] as Map<String, dynamic>),
        recentTasks: (json['recent_tasks'] as List<dynamic>)
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextThreshold: json['next_threshold'] as int? ?? 0,
        aiLine: json['ai_line'] as String? ?? '',
        gameOver: json['game_over'] as bool? ?? false,
      );
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000'),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));
  return ApiClient(dio);
});
