class Platform {
  final int id;
  final String name;
  final String displayName;
  final String baseUrl;
  final String logoUrl;

  Platform({
    required this.id,
    required this.name,
    required this.displayName,
    required this.baseUrl,
    this.logoUrl = '',
  });

  factory Platform.fromJson(Map<String, dynamic> json) {
    return Platform(
      id: json['id'],
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      baseUrl: json['base_url'] ?? '',
      logoUrl: json['logo_url'] ?? '',
    );
  }
}
