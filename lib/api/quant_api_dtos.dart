/// Data Transfer Objects (DTOs) for the Quant Spring Boot backend API.
///
/// These DTOs match the JSON contract used by the backend.
/// See docs/recipe_json_schema.md for the full JSON schema.

class RecipeDto {
  const RecipeDto({
    this.id,
    required this.title,
    this.description,
    this.servings,
    this.ingredients = const [],
    this.steps = const [],
    this.metadata,
  });

  final String? id;
  final String title;
  final String? description;
  final int? servings;
  final List<IngredientDto> ingredients;
  final List<RecipeStepDto> steps;
  final RecipeMetadataDto? metadata;

  factory RecipeDto.fromJson(Map<String, dynamic> json) {
    return RecipeDto(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      servings: json['servings'] as int?,
      ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
          .map((item) => IngredientDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((step) => RecipeStepDto.fromJson(step as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] != null
          ? RecipeMetadataDto.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (servings != null) 'servings': servings,
      'ingredients': ingredients.map((item) => item.toJson()).toList(),
      'steps': steps.map((step) => step.toJson()).toList(),
      if (metadata != null) 'metadata': metadata!.toJson(),
    };
  }
}

class IngredientDto {
  const IngredientDto({
    this.amount,
    this.unit,
    required this.item,
    this.notes,
  });

  final double? amount;
  final String? unit;
  final String item;
  final String? notes;

  factory IngredientDto.fromJson(Map<String, dynamic> json) {
    return IngredientDto(
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      item: json['item'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      'item': item,
      if (notes != null) 'notes': notes,
    };
  }
}

class RecipeStepDto {
  const RecipeStepDto({
    required this.step,
    required this.instruction,
    this.notes,
  });

  final int step;
  final String instruction;
  final String? notes;

  factory RecipeStepDto.fromJson(Map<String, dynamic> json) {
    return RecipeStepDto(
      step: json['step'] as int,
      instruction: json['instruction'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'instruction': instruction,
      if (notes != null) 'notes': notes,
    };
  }
}

class RecipeMetadataDto {
  const RecipeMetadataDto({
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

  factory RecipeMetadataDto.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and snake_case for backwards compatibility
    return RecipeMetadataDto(
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
    // Use snake_case to match backend JSON contract
    return {
      'source_url': sourceUrl ?? '',
      'author': author ?? '',
      if (language != null) 'language': language,
      'categories': categories,
      if (imageUrl != null) 'image_url': imageUrl,
      if (calculatorId != null) 'calculator_id': calculatorId,
      if (importMethod != null) 'import_method': importMethod,
    };
  }
}

class ImportRecipeRequestDto {
  const ImportRecipeRequestDto({
    required this.text,
    this.sourceUrl,
  });

  final String text;
  final String? sourceUrl;

  factory ImportRecipeRequestDto.fromJson(Map<String, dynamic> json) {
    return ImportRecipeRequestDto(
      text: json['text'] as String,
      sourceUrl: json['source_url'] as String? ?? json['sourceUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (sourceUrl != null) 'source_url': sourceUrl,
    };
  }
}
