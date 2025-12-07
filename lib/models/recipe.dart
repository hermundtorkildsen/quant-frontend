/// Core data models for Quant recipes.
///
/// JSON contract used by backend/AI for recipe import/export.
/// See docs/recipe_json_schema.md for details.
class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    this.description,
    this.servings,
    this.ingredients = const [],
    this.steps = const [],
    this.metadata,
  });

  final String id;
  final String title;
  final String? description;
  final int? servings;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final RecipeMetadata? metadata;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Handle nullable id from backend (e.g., imported recipes without id yet)
    final idValue = json['id'];
    final id = idValue == null
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : idValue as String;
    
    return Recipe(
      id: id,
      title: json['title'] as String,
      description: json['description'] as String?,
      servings: json['servings'] as int?,
      ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
          .map((item) => Ingredient.fromJson(item as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((step) => RecipeStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] != null
          ? RecipeMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'servings': servings,
      'ingredients': ingredients.map((item) => item.toJson()).toList(),
      'steps': steps.map((step) => step.toJson()).toList(),
      'metadata': metadata?.toJson(),
    };
  }
}

class Ingredient {
  const Ingredient({
    this.amount,
    this.unit,
    required this.item,
    this.notes,
  });

  final double? amount;
  final String? unit;
  final String item;
  final String? notes;

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      item: json['item'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'unit': unit,
      'item': item,
      'notes': notes,
    };
  }
}

class RecipeStep {
  const RecipeStep({
    required this.step,
    required this.instruction,
    this.notes,
  });

  final int step;
  final String instruction;
  final String? notes;

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      step: json['step'] as int,
      instruction: json['instruction'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'instruction': instruction,
      'notes': notes,
    };
  }
}

/// Recipe metadata following the JSON contract.
/// See docs/recipe_json_schema.md for details.
class RecipeMetadata {
  const RecipeMetadata({
    this.sourceUrl,
    this.author,
    this.language,
    this.categories = const [],
    this.imageUrl,
    this.calculatorId,
    this.importMethod,
  });

  final String? sourceUrl;
  final String? author;
  final String? language;
  final List<String> categories;
  final String? imageUrl;
  final String? calculatorId;
  final String? importMethod;

  factory RecipeMetadata.fromJson(Map<String, dynamic> json) {
    // Support both camelCase (legacy) and snake_case (contract) for backwards compatibility
    return RecipeMetadata(
      sourceUrl: json['source_url'] as String? ?? json['sourceUrl'] as String?,
      author: json['author'] as String?,
      language: json['language'] as String?,
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      calculatorId: json['calculator_id'] as String? ?? json['calculatorId'] as String?,
      importMethod: json['import_method'] as String? ?? json['importMethod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    // Use snake_case for fields that are part of the JSON contract
    return {
      'source_url': sourceUrl ?? '',
      'author': author ?? '',
      'language': language,
      'categories': categories,
      'image_url': imageUrl,
      'calculator_id': calculatorId,
      'import_method': importMethod,
    };
  }
}
