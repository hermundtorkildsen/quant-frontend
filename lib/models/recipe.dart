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
    this.sharedFromUsername,
    this.isFavorite = false,
    this.isPinned = false,
    this.favoritedAt,
    this.pinnedAt,
    this.createdAt,
    this.updatedAt,
    this.lastViewedAt,
    this.viewCount = 0,
  });

  final String id;
  final String title;
  final String? description;
  final int? servings;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final RecipeMetadata? metadata;

  /// If this recipe was created by accepting a share, this is who shared it.
  final String? sharedFromUsername;

  final bool isFavorite;
  final bool isPinned;
  final DateTime? favoritedAt;
  final DateTime? pinnedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastViewedAt;
  final int viewCount;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final v = value.trim();
      if (v.isEmpty) return null;
      return DateTime.tryParse(v);
    }
    return null;
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'y' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'n' || v == 'no') return false;
    }
    return defaultValue;
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Handle nullable id from backend
    final idValue = json['id'];
    final id = idValue == null
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : idValue as String;

    // Support multiple key variants (in case backend/older clients differ)
    final favoriteRaw =
        json['favorite'] ?? json['isFavorite'] ?? json['is_favorite'];
    final pinnedRaw = json['pinned'] ?? json['isPinned'] ?? json['is_pinned'];

    final favoritedAtRaw =
        json['favoritedAt'] ?? json['favorited_at'] ?? json['favoriteAt'];
    final pinnedAtRaw = json['pinnedAt'] ?? json['pinned_at'] ?? json['pinAt'];
    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    final updatedAtRaw = json['updatedAt'] ?? json['updated_at'];
    final lastViewedAtRaw = json['lastViewedAt'] ?? json['last_viewed_at'];
    final viewCountRaw = json['viewCount'] ?? json['view_count'];

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
      sharedFromUsername: json['sharedFromUsername'] as String?,

      // NEW
      isFavorite: _parseBool(favoriteRaw, defaultValue: false),
      isPinned: _parseBool(pinnedRaw, defaultValue: false),
      favoritedAt: _parseDateTime(favoritedAtRaw),
      pinnedAt: _parseDateTime(pinnedAtRaw),
      createdAt: _parseDateTime(createdAtRaw),
      updatedAt: _parseDateTime(updatedAtRaw),
      lastViewedAt: _parseDateTime(lastViewedAtRaw),
      viewCount: (viewCountRaw is num) ? viewCountRaw.toInt() : 0,
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

      // NEW: safe to include; backend can ignore if not used
      'favorite': isFavorite,
      'pinned': isPinned,
      if (favoritedAt != null) 'favoritedAt': favoritedAt!.toIso8601String(),
      if (pinnedAt != null) 'pinnedAt': pinnedAt!.toIso8601String(),
    };
  }
}

class Ingredient {
  const Ingredient({
    this.amount,
    this.unit,
    required this.item,
    this.notes,
    this.section,
  });

  final double? amount;
  final String? unit;
  final String item;
  final String? notes;
  final String? section;

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      item: json['item'] as String,
      notes: json['notes'] as String?,
      section: json['section'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'unit': unit,
      'item': item,
      'notes': notes,
      'section': section,
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
      calculatorId:
      json['calculator_id'] as String? ?? json['calculatorId'] as String?,
      importMethod:
      json['import_method'] as String? ?? json['importMethod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    // Use snake_case for fields that are part of the JSON contract
    return {
      'source_url': sourceUrl ?? '',
      'author': author ?? '',
      'language': language,
      'categories': categories,
      'image_url': imageUrl ?? '',
      'calculator_id': calculatorId,
      'import_method': importMethod,
    };
  }
}