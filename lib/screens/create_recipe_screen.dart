import 'package:flutter/material.dart';

import '../features/calculators/screens/calculators_screen.dart';
import '../models/recipe.dart';
import 'import_recipe_screen.dart';
import 'recipe_edit_screen.dart';

class CreateRecipeScreen extends StatelessWidget {
  const CreateRecipeScreen({super.key});

  void _createManual(BuildContext context) {
    final newRecipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Ny oppskrift',
      description: '',
      servings: null,
      ingredients: const [],
      steps: const [],
      metadata: RecipeMetadata(
        importMethod: 'manual',
        categories: const [],
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeEditScreen(recipe: newRecipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lag ny oppskrift'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Lag en ny oppskrift',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Start manuelt, importer, eller bruk et verktøy.',
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: () => _createManual(context),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Lag manuelt'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ImportRecipeScreen(initialTab: 0),
                    ),
                  );
                },
                icon: const Icon(Icons.text_snippet_outlined),
                label: const Text('Importer fra tekst'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ImportRecipeScreen(initialTab: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.link_outlined),
                label: const Text('Importer fra URL'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Importer fra bilde (kommer)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CalculatorsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Lag fra verktøy'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
