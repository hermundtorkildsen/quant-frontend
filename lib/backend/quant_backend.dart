// Models, repositories, services
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';
import '../services/mock_recipe_importer.dart';

// API HTTP backend
import '../api/quant_api_client.dart';
import '../api/quant_http_backend.dart';

import '../auth/token_store.dart';

/// High-level backend abstraction for the Quant app.
///
/// In production this will talk to a real HTTP API / Java backend.
/// For now we use a local in-memory mock implementation.
abstract class QuantBackend {
  Future<List<Recipe>> getAllRecipes();

  Future<Recipe?> getRecipeById(String id);

  Future<Recipe> saveRecipe(Recipe recipe);

  Future<void> deleteRecipe(String id);

  Future<void> shareRecipe(String recipeId, String toUsername, {String? message});

  /// Import a recipe from raw free text (and optional source URL).
  /// In production this would call an AI/parse endpoint on the backend.
  Future<Recipe> importRecipeFromText(String rawText, {String? sourceUrl});
  Future<int> getInboxCount();
  Future<List<Map<String, dynamic>>> getInbox();
  Future<Recipe> acceptShare(String shareId);
  Future<void> declineShare(String shareId);
  Future<Map<String, dynamic>> getMe();
  Future<Recipe> markViewed(String recipeId);

}

/// Mock implementation that keeps everything in memory and simulates
/// AI-based import locally.
class QuantBackendMock implements QuantBackend {
  QuantBackendMock() : _repository = InMemoryRecipeRepository();

  final RecipeRepository _repository;

  @override
  Future<List<Recipe>> getAllRecipes() {
    return _repository.getAllRecipes();
  }

  @override
  Future<Recipe?> getRecipeById(String id) {
    return _repository.getRecipeById(id);
  }

  @override
  Future<Recipe> saveRecipe(Recipe recipe) async {
    await _repository.saveRecipe(recipe);
    return recipe;
  }

  @override
  Future<void> deleteRecipe(String id) {
    return _repository.deleteRecipe(id);
  }

  @override
  Future<Recipe> importRecipeFromText(String rawText, {String? sourceUrl}) async {
    // Parse the recipe but don't save it yet - let the user review/edit first.
    // The UI will call saveRecipe() explicitly after user confirms.
    return await mockImportFromText(rawText, sourceUrl: sourceUrl?.trim());
  }

  @override
  Future<void> shareRecipe(String recipeId, String toUsername, {String? message}) async {
    // Ikke implementert i mock
  }

  @override
  Future<int> getInboxCount() async => 0;

  @override
  Future<List<Map<String, dynamic>>> getInbox() async => const [];

  @override
  Future<Recipe> acceptShare(String shareId) {
    throw UnimplementedError('acceptShare not implemented in mock');
  }

  @override
  Future<void> declineShare(String shareId) async {
    // noop
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    return {
      'username': 'mockuser',
    };
  }

  @override
  Future<Recipe> markViewed(String recipeId) async {
    final recipe = await _repository.getRecipeById(recipeId);
    if (recipe == null) {
      throw Exception('Recipe not found: $recipeId');
    }

    final updated = Recipe(
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      servings: recipe.servings,
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      metadata: recipe.metadata,
      sharedFromUsername: recipe.sharedFromUsername,
      isFavorite: recipe.isFavorite,
      isPinned: recipe.isPinned,
      favoritedAt: recipe.favoritedAt,
      pinnedAt: recipe.pinnedAt,
      createdAt: recipe.createdAt,
      updatedAt: recipe.updatedAt,
      lastViewedAt: DateTime.now(),
      viewCount: recipe.viewCount + 1,
    );

    await _repository.saveRecipe(updated);
    return updated;
  }


}

/// Global backend instance for the app. This allows the UI to use a single
/// abstraction (`QuantBackend`) and swap implementations later.
///
/// By default, uses Render cloud backend. To use local backend for development:
///   flutter run --dart-define=USE_CLOUD_BACKEND=false
const bool useCloudBackend = bool.fromEnvironment('USE_CLOUD_BACKEND', defaultValue: true);

final TokenStore tokenStore = TokenStore();

final QuantBackend quantBackend = QuantBackendHttp(
  QuantApiClient(
    baseUrl: useCloudBackend
        ? 'https://quant-backend-aism.onrender.com'
        : 'http://10.0.2.2:8080',
    tokenProvider: tokenStore.getToken,
  ),
  tokenStore,
);


// To switch back to mock backend for testing:
// final QuantBackend quantBackend = QuantBackendMock();


