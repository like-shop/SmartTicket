import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const OrderListScreen({super.key, this.embedded = false});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(orderProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final orders = state.orders;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('订单历史')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('暂无订单'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(orderProvider.notifier).loadOrders(),
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (ctx, i) {
                      final order = orders[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.receipt)),
                          title: Text(order.showName, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${order.ticketType} x${order.quantity}'),
                          trailing: Text('¥${order.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () => context.push('/orders/${order.id}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
