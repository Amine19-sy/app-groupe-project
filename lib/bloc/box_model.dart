class Box {
  final String id;
  final String userId;
  final String name;
  final String? description;

  Box({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
  });

  factory Box.fromJson(Map<String, dynamic> json) {
    return Box(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}
