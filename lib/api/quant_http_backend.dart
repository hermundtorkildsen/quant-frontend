import '../backend/quant_backend.dart';
import '../models/recipe.dart';
import 'quant_api_client.dart';
import 'quant_api_dtos.dart';

/// HTTP-based implementation of QuantBackend that communicates with a Spring Boot backend.
class QuantBackendHttp implements QuantBackend {
  QuantBackendHttp(this._apiClient);

  final QuantApiClient _apiClient;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    final dtos = await _apiClient.getAllRecipes();
    return dtos.map((dto) => _dtoToRecipe(dto)).toList();
  }

  @override
  Future<Recipe?> getRecipeById(String id) async {
    try {
      final dto = await _apiClient.getRecipeById(id);
      return _dtoToRecipe(dto);
    } catch (e) {
      if (e.toString().contains('not found')) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Recipe> saveRecipe(Recipe recipe) async {
    final dto = _recipeToDto(recipe);
    final savedDto = await _apiClient.saveRecipe(dto);
    return _dtoToRecipe(savedDto);
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await _apiClient.deleteRecipe(id);
  }

  @override
  Future<Recipe> importRecipeFromText(String rawText, {String? sourceUrl}) async {
    final request = ImportRecipeRequestDto(
      text: rawText,
      sourceUrl: sourceUrl,
    );
    final dto = await _apiClient.importRecipeFromText(request);
    return _dtoToRecipe(dto);
  }

  Recipe _dtoToRecipe(RecipeDto dto) {
    return Recipe(
      id: dto.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: dto.title,
      description: dto.description,
      servings: dto.servings,
      ingredients: dto.ingredients
          .map((ing) => Ingredient(
                amount: ing.amount,
                unit: ing.unit,
                item: ing.item,
                notes: ing.notes,
              ))
          .toList(),
      steps: dto.steps
          .map((step) => RecipeStep(
                step: step.step,
                instruction: step.instruction,
                notes: step.notes,
              ))
          .toList(),
      metadata: dto.metadata != null
          ? RecipeMetadata(
              sourceUrl: dto.metadata!.sourceUrl,
              author: dto.metadata!.author,
              language: dto.metadata!.language,
              categories: dto.metadata!.categories,
              imageUrl: dto.metadata!.imageUrl,
              calculatorId: dto.metadata!.calculatorId,
              importMethod: dto.metadata!.importMethod,
            )
          : null,
    );
  }

  RecipeDto _recipeToDto(Recipe recipe) {
    return RecipeDto(
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      servings: recipe.servings,
      ingredients: recipe.ingredients
          .map((ing) => IngredientDto(
                amount: ing.amount,
                unit: ing.unit,
                item: ing.item,
                notes: ing.notes,
              ))
          .toList(),
      steps: recipe.steps
          .map((step) => RecipeStepDto(
                step: step.step,
                instruction: step.instruction,
                notes: step.notes,
              ))
          .toList(),
      metadata: recipe.metadata != null
          ? RecipeMetadataDto(
              sourceUrl: recipe.metadata!.sourceUrl,
              author: recipe.metadata!.author,
              language: recipe.metadata!.language,
              categories: recipe.metadata!.categories,
              imageUrl: recipe.metadata!.imageUrl,
              calculatorId: recipe.metadata!.calculatorId,
              importMethod: recipe.metadata!.importMethod,
            )
          : null,
    );
  }
}
