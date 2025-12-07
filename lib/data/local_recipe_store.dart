import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/recipe.dart';

/// Simple file-based storage for recipes using JSON.
/// 
/// Stores recipes in a single JSON file in the app's documents directory.
class LocalRecipeStore {
  static const String _fileName = 'recipes.json';

  /// Gets the file path for storing recipes.
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Loads all recipes from the JSON file.
  /// Returns an empty list if the file doesn't exist or if loading fails.
  Future<List<Recipe>> loadRecipes() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        debugPrint('LocalRecipeStore: File does not exist, returning empty list');
        return [];
      }

      final contents = await file.readAsString();
      if (contents.trim().isEmpty) {
        debugPrint('LocalRecipeStore: File is empty, returning empty list');
        return [];
      }

      final jsonList = jsonDecode(contents) as List<dynamic>;
      final recipes = jsonList
          .map((json) => Recipe.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('LocalRecipeStore: Loaded ${recipes.length} recipes from file');
      return recipes;
    } catch (e) {
      debugPrint('LocalRecipeStore: Error loading recipes: $e');
      return [];
    }
  }

  /// Saves all recipes to the JSON file.
  /// Silently fails if saving encounters an error (logs to debugPrint).
  Future<void> saveRecipes(List<Recipe> recipes) async {
    try {
      final file = await _getFile();
      final jsonList = recipes.map((recipe) => recipe.toJson()).toList();
      final contents = jsonEncode(jsonList);
      await file.writeAsString(contents);
      debugPrint('LocalRecipeStore: Saved ${recipes.length} recipes to file');
    } catch (e) {
      debugPrint('LocalRecipeStore: Error saving recipes: $e');
      // Don't throw - allow app to continue with in-memory state
    }
  }
}


