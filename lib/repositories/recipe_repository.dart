import 'dart:async';

import '../data/local_recipe_store.dart';
import '../models/recipe.dart';

/// Abstraction for storing and retrieving recipes.
abstract class RecipeRepository {
  Future<List<Recipe>> getAllRecipes();

  Future<Recipe?> getRecipeById(String id);

  Future<void> saveRecipe(Recipe recipe);

  Future<void> deleteRecipe(String id);
}

/// Simple in-memory implementation for early development and testing.
/// Persists recipes to a local JSON file.
class InMemoryRecipeRepository implements RecipeRepository {
  InMemoryRecipeRepository() : _store = LocalRecipeStore() {
    _initialize();
  }

  final LocalRecipeStore _store;
  final List<Recipe> _recipes = [];
  bool _isInitialized = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  /// Initializes the repository by loading recipes from disk.
  /// Falls back to seed data if file doesn't exist or is empty.
  Future<void> _initialize() async {
    try {
      final loadedRecipes = await _store.loadRecipes();
      if (loadedRecipes.isNotEmpty) {
        _recipes.addAll(loadedRecipes);
      } else {
        // File doesn't exist or is empty, use seed data
        _recipes.addAll(_seedRecipes());
        // Save seed data to file for future use
        await _store.saveRecipes(_recipes);
      }
    } catch (e) {
      // If loading fails, fall back to seed data
      _recipes.addAll(_seedRecipes());
    } finally {
      _isInitialized = true;
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
    }
  }

  /// Ensures the repository is initialized before operations.
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializationCompleter.future;
    }
  }

  /// Saves the current recipe list to disk.
  Future<void> _persist() async {
    await _ensureInitialized();
    await _store.saveRecipes(_recipes);
  }

  @override
  Future<List<Recipe>> getAllRecipes() async {
    await _ensureInitialized();
    return List.unmodifiable(_recipes);
  }

  @override
  Future<Recipe?> getRecipeById(String id) async {
    await _ensureInitialized();
    try {
      return _recipes.firstWhere((recipe) => recipe.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRecipe(Recipe recipe) async {
    await _ensureInitialized();
    final existingIndex =
        _recipes.indexWhere((existing) => existing.id == recipe.id);
    if (existingIndex >= 0) {
      _recipes[existingIndex] = recipe;
    } else {
      _recipes.add(recipe);
    }
    await _persist();
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await _ensureInitialized();
    _recipes.removeWhere((recipe) => recipe.id == id);
    await _persist();
  }

  static List<Recipe> _seedRecipes() {
    return [
      Recipe(
        id: 'recipe-bolognese',
        title: 'Weeknight Bolognese',
        description:
            'A simple tomato-based sauce with beef, finished with parmesan.',
        servings: 4,
        ingredients: const [
          Ingredient(
            amount: 500,
            unit: 'g',
            item: 'ground beef',
          ),
          Ingredient(
            amount: 1,
            unit: 'pc',
            item: 'yellow onion',
            notes: 'finely diced',
          ),
          Ingredient(
            amount: 400,
            unit: 'g',
            item: 'crushed tomatoes',
          ),
        ],
        steps: const [
          RecipeStep(
            step: 1,
            instruction: 'Sauté onion in olive oil until translucent.',
          ),
          RecipeStep(
            step: 2,
            instruction: 'Add beef, cook until browned.',
          ),
          RecipeStep(
            step: 3,
            instruction:
                'Stir in tomatoes, simmer for 20 minutes, season to taste.',
          ),
        ],
        metadata: const RecipeMetadata(
          sourceUrl: 'https://example.com/bolognese',
          author: 'Quant Example',
          language: 'en',
          categories: ['pasta', 'sauce'],
          imageUrl:
              'https://images.pexels.com/photos/1279330/pexels-photo-1279330.jpeg',
        ),
      ),
      Recipe(
        id: 'recipe-hydration-dough',
        title: '70% Hydration Pizza Dough',
        description: 'Lean dough geared for 24h cold ferment.',
        servings: 2,
        ingredients: const [
          Ingredient(
            amount: 500,
            unit: 'g',
            item: '00 flour',
          ),
          Ingredient(
            amount: 350,
            unit: 'g',
            item: 'water',
          ),
          Ingredient(
            amount: 15,
            unit: 'g',
            item: 'salt',
          ),
          Ingredient(
            amount: 1,
            unit: 'g',
            item: 'instant yeast',
          ),
        ],
        steps: const [
          RecipeStep(
            step: 1,
            instruction: 'Mix water and flour, rest 30 minutes (autolyse).',
          ),
          RecipeStep(
            step: 2,
            instruction: 'Add salt and yeast, knead until smooth.',
            notes: 'Add water gradually to keep hydration consistent.',
          ),
          RecipeStep(
            step: 3,
            instruction:
                'Bulk ferment 2h at room temp, ball, then cold ferment 24h.',
          ),
        ],
        metadata: const RecipeMetadata(
          author: 'Quant Example',
          language: 'en',
          categories: ['pizza', 'dough'],
          imageUrl:
              'https://images.pexels.com/photos/4109084/pexels-photo-4109084.jpeg',
        ),
      ),
      Recipe(
        id: 'recipe-sourdough-country-loaf',
        title: 'Country Sourdough Loaf 75% Hydration',
        description:
            'Open crumb, dark crust sourdough designed for overnight cold retard.',
        servings: 1,
        ingredients: const [
          Ingredient(
            amount: 800,
            unit: 'g',
            item: 'bread flour',
          ),
          Ingredient(
            amount: 600,
            unit: 'g',
            item: 'water',
          ),
          Ingredient(
            amount: 160,
            unit: 'g',
            item: 'active sourdough starter',
          ),
          Ingredient(
            amount: 18,
            unit: 'g',
            item: 'salt',
          ),
        ],
        steps: const [
          RecipeStep(
            step: 1,
            instruction: 'Mix flour and water, rest 60 minutes (autolyse).',
          ),
          RecipeStep(
            step: 2,
            instruction: 'Add starter and salt, mix until well incorporated.',
          ),
          RecipeStep(
            step: 3,
            instruction:
                'Bulk ferment 4–5 hours with coil folds every 30 minutes for the first 2 hours.',
          ),
          RecipeStep(
            step: 4,
            instruction:
                'Pre-shape, rest 20 minutes, final shape and cold retard 12–16 hours.',
          ),
        ],
        metadata: const RecipeMetadata(
          author: 'Quant Example',
          language: 'en',
          categories: ['bread', 'sourdough', 'high hydration'],
          imageUrl:
              'https://images.pexels.com/photos/2092063/pexels-photo-2092063.jpeg',
        ),
      ),
      Recipe(
        id: 'recipe-focaccia-olive-oil',
        title: 'Olive Oil Pan Focaccia',
        description:
            'Crisp, oily bottom and airy crumb, perfect for sharing or sandwich slabs.',
        servings: 8,
        ingredients: const [
          Ingredient(
            amount: 500,
            unit: 'g',
            item: 'strong white flour',
          ),
          Ingredient(
            amount: 400,
            unit: 'g',
            item: 'water',
          ),
          Ingredient(
            amount: 10,
            unit: 'g',
            item: 'instant yeast',
          ),
          Ingredient(
            amount: 12,
            unit: 'g',
            item: 'salt',
          ),
          Ingredient(
            amount: 60,
            unit: 'g',
            item: 'extra-virgin olive oil',
            notes: 'plus more for the pan and topping',
          ),
          Ingredient(
            amount: null,
            unit: null,
            item: 'flaky salt',
            notes: 'for finishing',
          ),
          Ingredient(
            amount: null,
            unit: null,
            item: 'rosemary sprigs',
            notes: 'optional',
          ),
        ],
        steps: const [
          RecipeStep(
            step: 1,
            instruction:
                'Mix all ingredients until no dry flour remains. Rest 10 minutes.',
          ),
          RecipeStep(
            step: 2,
            instruction:
                'Perform 3–4 stretch and folds every 15 minutes, then bulk ferment until doubled.',
          ),
          RecipeStep(
            step: 3,
            instruction:
                'Transfer to generously oiled pan, rest 30–40 minutes, then dimple with oiled fingers.',
          ),
          RecipeStep(
            step: 4,
            instruction:
                'Top with olive oil, flaky salt, and rosemary. Bake at 230°C until deeply golden.',
          ),
        ],
        metadata: const RecipeMetadata(
          author: 'Quant Example',
          language: 'en',
          categories: ['bread', 'focaccia', 'olive oil'],
          imageUrl:
              'https://images.pexels.com/photos/4109085/pexels-photo-4109085.jpeg',
        ),
      ),
      Recipe(
        id: 'recipe-chocolate-chip-cookies',
        title: 'Brown Butter Chocolate Chip Cookies',
        description:
            'Crispy edges, chewy center, with nutty brown butter and dark chocolate.',
        servings: 24,
        ingredients: const [
          Ingredient(
            amount: 225,
            unit: 'g',
            item: 'unsalted butter',
            notes: 'browned and cooled',
          ),
          Ingredient(
            amount: 200,
            unit: 'g',
            item: 'brown sugar',
          ),
          Ingredient(
            amount: 100,
            unit: 'g',
            item: 'white sugar',
          ),
          Ingredient(
            amount: 2,
            unit: 'pc',
            item: 'eggs',
          ),
          Ingredient(
            amount: 280,
            unit: 'g',
            item: 'all-purpose flour',
          ),
          Ingredient(
            amount: 5,
            unit: 'g',
            item: 'baking soda',
          ),
          Ingredient(
            amount: 5,
            unit: 'g',
            item: 'salt',
          ),
          Ingredient(
            amount: 250,
            unit: 'g',
            item: 'dark chocolate',
            notes: 'coarsely chopped',
          ),
        ],
        steps: const [
          RecipeStep(
            step: 1,
            instruction:
                'Brown the butter, cool slightly, then whisk with sugars until glossy.',
          ),
          RecipeStep(
            step: 2,
            instruction: 'Add eggs one at a time, then fold in dry ingredients.',
          ),
          RecipeStep(
            step: 3,
            instruction: 'Fold in chocolate, chill dough at least 1 hour.',
          ),
          RecipeStep(
            step: 4,
            instruction:
                'Scoop onto tray and bake at 180°C until edges are golden and centers just set.',
          ),
        ],
        metadata: const RecipeMetadata(
          author: 'Quant Example',
          language: 'en',
          categories: ['cookies', 'dessert'],
          imageUrl:
              'https://images.pexels.com/photos/2303259/pexels-photo-2303259.jpeg',
        ),
      ),
      Recipe(
        id: 'recipe-classic-risotto',
        title: 'Classic Parmesan Risotto',
        description:
            'Stovetop risotto with white wine, butter, and a heap of Parmigiano Reggiano.',
        servings: 4,
        ingredients: const [
          Ingredient(
            amount: 320,
            unit: 'g',
            item: 'arborio rice',
          ),
          Ingredient(
            amount: 1,
            unit: 'pc',
            item: 'shallot',
            notes: 'finely minced',
          ),
          Ingredient(
            amount: 120,
            unit: 'ml',
            item: 'dry white wine',
          ),
          Ingredient(
            amount: 1,
            unit: 'l',
            item: 'chicken or vegetable stock',
            notes: 'kept hot',
          ),
          Ingredient(
            amount: 60,
            unit: 'g',
            item: 'unsalted butter',
          ),
          Ingredient(
            amount: 80,
            unit: 'g',
            item: 'Parmesan cheese',
            notes: 'finely grated',
          ),
          Ingredient(
            amount: null,
            unit: null,
            item: 'salt and pepper',
            notes: 'to taste',
          ),
        ],
        steps: const [
          RecipeStep(
            step: 1,
            instruction:
                'Sweat shallot in butter until soft, then add rice and toast lightly.',
          ),
          RecipeStep(
            step: 2,
            instruction:
                'Deglaze with white wine and cook until almost fully absorbed.',
          ),
          RecipeStep(
            step: 3,
            instruction:
                'Add hot stock a ladle at a time, stirring often until rice is al dente and creamy.',
          ),
          RecipeStep(
            step: 4,
            instruction:
                'Off heat, stir in remaining butter and Parmesan, season to taste, and serve immediately.',
          ),
        ],
        metadata: const RecipeMetadata(
          author: 'Quant Example',
          language: 'en',
          categories: ['risotto', 'rice', 'pasta'],
          imageUrl:
              'https://images.pexels.com/photos/6287521/pexels-photo-6287521.jpeg',
        ),
      ),
    ];
  }
}

/// Global in-memory repository instance that can be reused across the app
/// before a real backend and dependency injection are introduced.
final RecipeRepository recipeRepository = InMemoryRecipeRepository();

