// lib/models/food.dart
class Food {
  final int? id;
  final String key;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final String imageUrl;

  Food({
    this.id,
    required this.key,
    required this.name,
    required this.description,
    this.ingredients = const [],
    this.instructions = const [],
    this.tags = const [],
    required this.imageUrl,
  });

  factory Food.fromJson(Map<String, dynamic> json, String baseUrl) {
    final id = json['id'] is int
        ? json['id'] as int
        : (json['id'] != null ? int.tryParse(json['id'].toString()) : null);

    final key = (json['key'] ?? json['key_name'] ?? '').toString();
    final safeBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

    final imagePath = (json['image'] ?? 'food_images/$key.jpg').toString();

    var fullImageUrl = imagePath.startsWith('/')
        ? '$safeBase${imagePath.substring(1)}'
        : '$safeBase$imagePath';

    final cacheBuster = DateTime.now().millisecondsSinceEpoch ~/ 120000;
    fullImageUrl += '?v=$cacheBuster';

    return Food(
      id: id,
      key: key,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      instructions: (json['instructions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      imageUrl: fullImageUrl,
    );
  }
}
