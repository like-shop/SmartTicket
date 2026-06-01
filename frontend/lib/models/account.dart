import 'platform.dart';

class PlatformAccount {
  final int id;
  final int platformId;
  final String accountLabel;
  final String accountUsername;
  final bool isVerified;
  final Platform? platform;

  PlatformAccount({
    required this.id,
    required this.platformId,
    required this.accountLabel,
    required this.accountUsername,
    this.isVerified = false,
    this.platform,
  });

  factory PlatformAccount.fromJson(Map<String, dynamic> json) {
    return PlatformAccount(
      id: json['id'],
      platformId: json['platform_id'] ?? 0,
      accountLabel: json['account_label'] ?? '',
      accountUsername: json['account_username'] ?? '',
      isVerified: json['is_verified'] ?? false,
      platform: json['platform'] != null ? Platform.fromJson(json['platform']) : null,
    );
  }
}
