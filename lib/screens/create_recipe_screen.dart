import 'package:flutter/material.dart';

import '../features/calculators/screens/calculators_screen.dart';
import '../models/recipe.dart';
import 'import_recipe_screen.dart';
import 'recipe_edit_screen.dart';
import 'import_from_image_screen.dart';
import 'import_from_file_screen.dart';

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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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

              _CreateActionCard(
                icon: Icons.edit_outlined,
                title: 'Lag manuelt',
                subtitle: 'Start med en tom oppskrift.',
                onTap: () => _createManual(context),
              ),
              const SizedBox(height: 12),

              _CreateActionCard(
                icon: Icons.text_snippet_outlined,
                title: 'Importer fra tekst',
                subtitle: 'Lim inn oppskrift fra notater eller nettside.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                      const ImportRecipeScreen(initialTab: 0),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _CreateActionCard(
                icon: Icons.link_outlined,
                title: 'Importer fra URL',
                subtitle: 'Hent oppskrift fra en lenke.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                      const ImportRecipeScreen(initialTab: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _CreateActionCard(
                icon: Icons.upload_file_outlined,
                title: 'Last opp fil',
                subtitle: 'Last opp PDF, Word eller tekstfil.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ImportFromFileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _CreateActionCard(
                icon: Icons.image_outlined,
                title: 'Importer fra bilde',
                subtitle: 'Velg et bilde og importer oppskriften.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ImportFromImageScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _CreateActionCard(
                icon: Icons.calculate_outlined,
                title: 'Lag fra verktøy',
                subtitle: 'Bruk kalkulator og lagre resultatet.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CalculatorsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateActionCard extends StatefulWidget {
  const _CreateActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  State<_CreateActionCard> createState() => _CreateActionCardState();
}

class _CreateActionCardState extends State<_CreateActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _pressed
                ? Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 22,
                color: enabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: textTheme.bodySmall?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
