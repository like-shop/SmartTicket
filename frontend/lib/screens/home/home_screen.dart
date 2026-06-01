import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../train/train_search_screen.dart';
import '../tasks/task_list_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartTicket'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: '订单',
            onPressed: () => context.push('/orders'),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: '平台账号',
            onPressed: () => context.push('/platforms'),
          ),
          IconButton(
            icon: const Icon(Icons.task_alt),
            tooltip: '抢票任务',
            onPressed: () => context.push('/tasks'),
          ),
        ],
      ),
      body: const TrainSearchScreen(embedded: true),
    );
  }
}
