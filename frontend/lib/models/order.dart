class Order {
  final int id;
  final String orderNumber;
  final String showName;
  final String ticketType;
  final int quantity;
  final double totalPrice;
  final String status;
  final String createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.showName,
    required this.ticketType,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      showName: json['show_name'] ?? '',
      ticketType: json['ticket_type'] ?? '',
      quantity: json['quantity'] ?? 0,
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
