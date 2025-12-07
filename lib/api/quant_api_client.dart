import 'dart:convert';
import 'package:http/http.dart' as http;

import 'quant_api_dtos.dart';

/// HTTP client for communicating with the Quant Spring Boot backend API.
///
/// TODO: Add authentication headers when auth is implemented.
/// TODO: Add retry logic for network failures.
/// TODO: Add request/response logging for debugging.
class QuantApiClient {
  QuantApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  /// Get all recipes for the current user.
  ///
  /// GET /api/recipes
  Future<List<RecipeDto>> getAllRecipes() async {
    final uri = Uri.parse('$baseUrl/api/recipes');
    final response = await _http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load recipes: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
    return jsonList
        .map((json) => RecipeDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single recipe by ID.
  ///
  /// GET /api/recipes/{id}
  Future<RecipeDto> getRecipeById(String id) async {
    final uri = Uri.parse('$baseUrl/api/recipes/$id');
    final response = await _http.get(uri);

    if (response.statusCode == 404) {
      throw Exception('Recipe not found: $id');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load recipe: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return RecipeDto.fromJson(json);
  }

  /// Create or update a recipe.
  ///
  /// POST /api/recipes (for new recipes without ID or with new ID)
  /// PUT /api/recipes/{id} (for existing recipes)
  ///
  /// TODO: Backend should clarify if POST or PUT is used for updates.
  /// For now, we use POST and let backend decide based on ID presence.
  Future<RecipeDto> saveRecipe(RecipeDto dto) async {
    final uri = Uri.parse('$baseUrl/api/recipes');
    final body = jsonEncode(dto.toJson());
    final headers = {'Content-Type': 'application/json'};

    final response = await _http.post(
      uri,
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to save recipe: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return RecipeDto.fromJson(json);
  }

  /// Delete a recipe by ID.
  ///
  /// DELETE /api/recipes/{id}
  Future<void> deleteRecipe(String id) async {
    final uri = Uri.parse('$baseUrl/api/recipes/$id');
    final response = await _http.delete(uri);

    if (response.statusCode == 404) {
      // Recipe not found - consider this a success (idempotent delete)
      return;
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete recipe: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Import a recipe from raw text using AI parsing.
  ///
  /// POST /api/recipes/import-text
  Future<RecipeDto> importRecipeFromText(ImportRecipeRequestDto request) async {
    final uri = Uri.parse('$baseUrl/api/recipes/import-text');
    final body = jsonEncode(request.toJson());
    final headers = {'Content-Type': 'application/json'};

    final response = await _http.post(
      uri,
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to import recipe: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return RecipeDto.fromJson(json);
  }
}




