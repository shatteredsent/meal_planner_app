class Recipe {
  final int? id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String? imageUrl;
  final String category;

  Recipe({
    this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    this.imageUrl,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'imageUrl': imageUrl,
      'category': category,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
  return Recipe(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    ingredients: json['ingredients'] is String
      ? (json['ingredients'] as String).contains(';')
        ? (json['ingredients'] as String).split(';')
        : (json['ingredients'] as String).split('|')
      : List<String>.from(json['ingredients'] ?? []),
    instructions: json['instructions'] is String
      ? (json['instructions'] as String).contains(';')
        ? (json['instructions'] as String).split(';')
        : (json['instructions'] as String).split('|')
      : List<String>.from(json['instructions'] ?? []),
    prepTime: json['prepTime'] ?? json['prep_time'],
    cookTime: json['cookTime'] ?? json['cook_time'],
    servings: json['servings'],
    imageUrl: json['imageUrl'] ?? json['image_url'],
    category: json['category'],
  );
  }
}