import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class LiveActivityTask {
  final String id;
  final String title;
  final DateTime deadline;

  LiveActivityTask({required this.id, required this.title, required this.deadline});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'deadline': (deadline.millisecondsSinceEpoch / 1000).round(),
  };
}

class LiveActivityService {
  static const _channel = MethodChannel('com.aitodo.liveActivity');

  Future<void> updateTasks(List<LiveActivityTask> tasks) async {
    if (!Platform.isIOS) return;

    try {
      final tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());
      await _channel.invokeMethod('updateTasks', {
        'tasksJson': tasksJson,
      });
      print('[LiveActivity] Updated tasks: ${tasks.length}');
    } catch (e) {
      print('[LiveActivity] Failed to update: $e');
    }
  }
  
  Future<void> stopAll() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('stopActivity');
      print('[LiveActivity] Stopped all');
    } catch (e) {
      print('[LiveActivity] Failed to stop: $e');
    }
  }
}

final liveActivityService = LiveActivityService();
