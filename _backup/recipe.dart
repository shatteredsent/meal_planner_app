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
	List<String> parseListOrString(dynamic value) {
		if (value == null) return [];
		if (value is List) {
			return value.map((e) => e.toString()).toList();
		}
		if (value is String) {
			if (value.contains(';')) {
				return value.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
			} else if (value.contains('|')) {
				return value.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
			} else {
				return [value.trim()];
			}
		}
		return [];
	}
	return Recipe(
		id: json['id'],
		name: json['name'],
		description: json['description'],
		ingredients: parseListOrString(json['ingredients']),
		instructions: parseListOrString(json['instructions']),
		prepTime: json['prepTime'] ?? json['prep_time'],
		cookTime: json['cookTime'] ?? json['cook_time'],
		servings: json['servings'],
		imageUrl: json['imageUrl'] ?? json['image_url'],
		category: json['category'],
	);
	}
}
...existing code...
