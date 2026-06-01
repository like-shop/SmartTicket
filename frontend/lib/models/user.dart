class User {
  final int id;
  final String phone;
  final String nickname;
  final String avatar;

  User({
    required this.id,
    required this.phone,
    this.nickname = '',
    this.avatar = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'] ?? '',
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'phone': phone, 'nickname': nickname, 'avatar': avatar,
  };
}
