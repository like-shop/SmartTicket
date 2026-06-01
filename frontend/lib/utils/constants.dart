import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'SmartTicket';
  static const String appVersion = '1.0.0';
}

Map<String, String> statusLabels = {
  'pending': '待调度',
  'scheduled': '已调度',
  'monitoring': '监控中',
  'purchasing': '抢票中',
  'completed': '已完成',
  'failed': '已失败',
  'cancelled': '已取消',
};

Map<String, Color> statusColors = {
  'pending': Colors.grey,
  'scheduled': Colors.blue,
  'monitoring': Colors.orange,
  'purchasing': Colors.red,
  'completed': Colors.green,
  'failed': Colors.red,
  'cancelled': Colors.grey,
};
