import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderProvider);
    final order = state.orders.where((o) => o.id == orderId).firstOrNull;

    if (order == null) {
      return Scaffold(appBar: AppBar(title: const Text('订单详情')), body: const Center(child: Text('订单未找到')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.showName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _row('订单号', order.orderNumber),
            _row('票档', order.ticketType),
            _row('数量', '${order.quantity} 张'),
            _row('总价', '¥${order.totalPrice.toStringAsFixed(2)}'),
            _row('状态', order.status),
            _row('时间', order.createdAt),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
