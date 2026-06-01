import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/home/home_screen.dart';
import '../screens/platforms/platform_list_screen.dart';
import '../screens/platforms/account_form_screen.dart';
import '../screens/tasks/task_list_screen.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../screens/orders/order_list_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/captcha/captcha_solve_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/platforms', builder: (_, __) => const PlatformListScreen()),
      GoRoute(path: '/platforms/add', builder: (_, __) => const AccountFormScreen()),
      GoRoute(path: '/platforms/:id/edit', builder: (_, state) => AccountFormScreen(accountId: int.tryParse(state.pathParameters['id'] ?? ''))),
      GoRoute(path: '/tasks', builder: (_, __) => const TaskListScreen()),
      GoRoute(path: '/tasks/:id', builder: (_, state) => TaskDetailScreen(taskId: int.parse(state.pathParameters['id']!))),
      GoRoute(path: '/orders', builder: (_, __) => const OrderListScreen()),
      GoRoute(path: '/orders/:id', builder: (_, state) => OrderDetailScreen(orderId: int.parse(state.pathParameters['id']!))),
      GoRoute(path: '/captcha', builder: (_, __) => const CaptchaSolveScreen()),
    ],
  );
});
