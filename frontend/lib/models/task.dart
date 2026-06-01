import 'account.dart';

class TicketTask {
  final int id;
  final int platformAccountId;
  final String showName;
  final String showUrl;
  final String? targetDate;
  final String saleTime;
  final String ticketType;
  final int quantity;
  final String status;
  final PlatformAccount? platformAccount;

  TicketTask({
    required this.id,
    required this.platformAccountId,
    required this.showName,
    required this.showUrl,
    this.targetDate,
    required this.saleTime,
    this.ticketType = '',
    this.quantity = 1,
    this.status = 'pending',
    this.platformAccount,
  });

  factory TicketTask.fromJson(Map<String, dynamic> json) {
    return TicketTask(
      id: json['id'],
      platformAccountId: json['platform_account_id'] ?? 0,
      showName: json['show_name'] ?? '',
      showUrl: json['show_url'] ?? '',
      targetDate: json['target_date'],
      saleTime: json['sale_time'] ?? '',
      ticketType: json['ticket_type'] ?? '',
      quantity: json['quantity'] ?? 1,
      status: json['status'] ?? 'pending',
      platformAccount: json['platform_account'] != null
          ? PlatformAccount.fromJson(json['platform_account'])
          : null,
    );
  }
}
