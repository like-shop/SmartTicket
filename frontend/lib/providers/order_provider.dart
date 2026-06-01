import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'api_provider.dart';

class OrderState {
  final List<Order> orders;
  final bool isLoading;

  OrderState({this.orders = const [], this.isLoading = false});

  OrderState copyWith({List<Order>? orders, bool? isLoading}) {
    return OrderState(orders: orders ?? this.orders, isLoading: isLoading ?? this.isLoading);
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderService _service;

  OrderNotifier(this._service) : super(OrderState());

  Future<void> loadOrders({String? status}) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _service.getOrders(status: status);
      state = state.copyWith(
        orders: data.map((j) => Order.fromJson(j)).toList(),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final service = OrderService(apiClient);
  return OrderNotifier(service);
});
