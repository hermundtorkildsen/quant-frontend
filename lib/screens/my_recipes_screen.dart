import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backend/quant_backend.dart';
import '../features/calculators/screens/pizza_calculator_screen.dart';
import '../models/recipe.dart';
import 'import_from_text_screen.dart';
import 'recipe_edit_screen.dart';

/// Helper to get a human-readable origin label for a recipe in Norwegian.
String? _getOriginLabel(Recipe recipe) {
  final importMethod = recipe.metadata?.importMethod;
  final calculatorId = recipe.metadata?.calculatorId;

  if (importMethod == 'calculator') {
    if (calculatorId == 'pizza') {
      return 'Fra pizzakalkulator';
    }
    return 'Fra kalkulator';
  } else if (importMethod == 'text') {
    return 'Importert fra tekst';
  } else if (importMethod == 'manual' || importMethod == null) {
    return 'Manuelt opprettet';
  }

  return null;
}

/// Reusable widget that displays origin and category chips for a recipe.
class RecipeOriginAndCategoryChips extends StatelessWidget {
  const RecipeOriginAndCategoryChips({
    super.key,
    required this.recipe,
  });

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final originLabel = _getOriginLabel(recipe);
    final categories = recipe.metadata?.categories ?? const <String>[];
    final hasChips = originLabel != null || categories.isNotEmpty;

    if (!hasChips) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (originLabel != null)
            Chip(
              label: Text(originLabel),
              visualDensity: VisualDensity.compact,
            ),
          for (final category in categories)
            Chip(
              label: Text(category),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

/// Reusable widget that displays recipe action buttons (Edit, Scale, Convert).
class RecipeActionButtons extends StatelessWidget {
  const RecipeActionButtons({
    super.key,
    required this.onEdit,
    required this.onScale,
    required this.onConvert,
  });

  final VoidCallback onEdit;
  final VoidCallback onScale;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Rediger'),
        ),
        OutlinedButton.icon(
          onPressed: onScale,
          icon: const Icon(Icons.scale_outlined),
          label: const Text('Skaler'),
        ),
        OutlinedButton.icon(
          onPressed: onConvert,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Konverter'),
        ),
      ],
    );
  }
}

/// Screen showing recipes the user has saved, with search and tag filtering.
class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  String _searchQuery = '';
  String? _selectedTag;
  RecipeOriginFilter _originFilter = RecipeOriginFilter.all;
  late final TextEditingController _searchController;
  late Future<List<Recipe>> _recipesFuture;
  RecipeSortMode _sortMode = RecipeSortMode.titleAsc;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _searchQuery);
    // Fetch recipes once; filtering is done client-side without reloading.
    _recipesFuture = quantBackend.getAllRecipes();
  }

  void _reloadRecipes() {
    setState(() {
      _recipesFuture = quantBackend.getAllRecipes();
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value;
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mine oppskrifter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_snippet_outlined),
            tooltip: 'Importer fra tekst',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ImportFromTextScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<RecipeSortMode>(
            tooltip: 'Sorter',
            icon: const Icon(Icons.sort),
            onSelected: (mode) {
              setState(() {
                _sortMode = mode;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: RecipeSortMode.titleAsc,
                child: Text('Tittel A–Å'),
              ),
              PopupMenuItem(
                value: RecipeSortMode.titleDesc,
                child: Text('Tittel Å–A'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Kunne ikke laste oppskrifter.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          final recipes = snapshot.data ?? const [];

          if (recipes.isEmpty) {
            return _EmptyState();
          }

          final allTags = <String>{
            for (final r in recipes) ...?r.metadata?.categories,
          }.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          // Apply origin filter first
          var filtered = recipes;
          switch (_originFilter) {
            case RecipeOriginFilter.manual:
              filtered = recipes.where((r) {
                final m = r.metadata;
                final method = m?.importMethod;
                return method == 'manual' || method == null;
              }).toList();
              break;
            case RecipeOriginFilter.pizzaCalculator:
              filtered = recipes.where((r) {
                final m = r.metadata;
                return m?.importMethod == 'calculator' && m?.calculatorId == 'pizza';
              }).toList();
              break;
            case RecipeOriginFilter.imported:
              filtered = recipes.where((r) => r.metadata?.importMethod == 'text').toList();
              break;
            case RecipeOriginFilter.all:
              // keep as-is
              break;
          }

          // Apply search and tag filters
          filtered = filtered.where((recipe) {
            final q = _searchQuery.trim().toLowerCase();
            final matchesQuery = q.isEmpty ||
                recipe.title.toLowerCase().contains(q) ||
                (recipe.description ?? '').toLowerCase().contains(q) ||
                (recipe.metadata?.categories ?? [])
                    .any((c) => c.toLowerCase().contains(q));

            final matchesTag = _selectedTag == null ||
                (recipe.metadata?.categories ?? [])
                    .map((c) => c.toLowerCase())
                    .contains(_selectedTag!.toLowerCase());

            return matchesQuery && matchesTag;
          }).toList();

          // Apply sorting.
          filtered.sort((a, b) {
            final at = a.title.toLowerCase();
            final bt = b.title.toLowerCase();
            final cmp = at.compareTo(bt);
            return _sortMode == RecipeSortMode.titleAsc ? cmp : -cmp;
          });

          final hasActiveFilters =
              _searchQuery.trim().isNotEmpty ||
              _selectedTag != null ||
              _originFilter != RecipeOriginFilter.all;

          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OriginFilterRow(
                    selectedFilter: _originFilter,
                    onFilterSelected: (filter) {
                      setState(() {
                        _originFilter = filter;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _RecipeSearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 8),
                  _TagFilterRow(
                    tags: allTags,
                    selectedTag: _selectedTag,
                    onTagSelected: (tag) {
                      setState(() {
                        _selectedTag = tag == _selectedTag ? null : tag;
                      });
                    },
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedTag = null;
                          _originFilter = RecipeOriginFilter.all;
                          _searchController.clear();
                        });
                      },
                      child: const Text('Nullstill filtre'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Ingen oppskrifter matcher filtrene dine.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: filtered.length + 1,
            separatorBuilder: (context, index) =>
                index == 0 ? const SizedBox(height: 12) : const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OriginFilterRow(
                      selectedFilter: _originFilter,
                      onFilterSelected: (filter) {
                        setState(() {
                          _originFilter = filter;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _RecipeSearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 8),
                    _TagFilterRow(
                      tags: allTags,
                      selectedTag: _selectedTag,
                      onTagSelected: (tag) {
                        setState(() {
                          _selectedTag = tag == _selectedTag ? null : tag;
                        });
                      },
                    ),
                    if (hasActiveFilters) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _selectedTag = null;
                            _originFilter = RecipeOriginFilter.all;
                            _searchController.clear();
                          });
                        },
                        child: const Text('Nullstill filtre'),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                );
              }

              final recipe = filtered[index - 1];
              return _RecipeListTile(
                recipe: recipe,
                onRecipeDeleted: _reloadRecipes,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final newRecipe = Recipe(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: '',
            description: '',
            servings: 1,
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
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RecipeSearchBar extends StatelessWidget {
  const _RecipeSearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
            hintText: 'Søk i oppskrifter...',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

enum RecipeSortMode {
  titleAsc,
  titleDesc,
}

enum RecipeOriginFilter {
  all,
  manual,
  pizzaCalculator,
  imported,
}

class _OriginFilterRow extends StatelessWidget {
  const _OriginFilterRow({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final RecipeOriginFilter selectedFilter;
  final ValueChanged<RecipeOriginFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Alle'),
            selected: selectedFilter == RecipeOriginFilter.all,
            onSelected: (_) => onFilterSelected(RecipeOriginFilter.all),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Manuelt'),
            selected: selectedFilter == RecipeOriginFilter.manual,
            onSelected: (_) => onFilterSelected(RecipeOriginFilter.manual),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Pizzakalkulator'),
            selected: selectedFilter == RecipeOriginFilter.pizzaCalculator,
            onSelected: (_) => onFilterSelected(RecipeOriginFilter.pizzaCalculator),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Importert'),
            selected: selectedFilter == RecipeOriginFilter.imported,
            onSelected: (_) => onFilterSelected(RecipeOriginFilter.imported),
          ),
        ],
      ),
    );
  }
}

class _TagFilterRow extends StatelessWidget {
  const _TagFilterRow({
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  final List<String> tags;
  final String? selectedTag;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tag in tags) ...[
            ChoiceChip(
              label: Text(tag),
              selected: selectedTag != null &&
                  selectedTag!.toLowerCase() == tag.toLowerCase(),
              onSelected: (_) => onTagSelected(tag),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _RecipeListTile extends StatelessWidget {
  const _RecipeListTile({
    required this.recipe,
    required this.onRecipeDeleted,
  });

  final Recipe recipe;
  final VoidCallback onRecipeDeleted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final servingsText =
        recipe.servings != null ? '${recipe.servings} servings' : null;
    final tags = recipe.metadata?.categories ?? const <String>[];
    final imageUrl = recipe.metadata?.imageUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: imageUrl == null || imageUrl.isEmpty
            ? null
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) {
                    return Container(
                      width: 56,
                      height: 56,
                      color: Colors.black.withOpacity(0.04),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
        title: Text(
          recipe.title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.description != null &&
                recipe.description!.trim().isNotEmpty)
              Text(
                recipe.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (servingsText != null) ...[
              const SizedBox(height: 4),
              Text(servingsText),
            ],
            Builder(
              builder: (context) {
                final originLabel = _getOriginLabel(recipe);
                if (originLabel != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      originLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: textTheme.bodySmall?.color?.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _formatTags(tags),
                style: textTheme.bodySmall?.copyWith(
                  color: textTheme.bodySmall?.color?.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final deleted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipe: recipe),
            ),
          );
          if (deleted == true) {
            onRecipeDeleted();
          }
        },
      ),
    );
  }

  String _formatTags(List<String> tags) {
    if (tags.isEmpty) return '';
    const maxToShow = 3;
    final visible = tags.take(maxToShow).toList();
    final remaining = tags.length - visible.length;
    final base = visible.join(' · ');
    if (remaining > 0) {
      return '$base · +$remaining';
    }
    return base;
  }
}

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;
  int? _scaledServings;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  double get _scaleFactor {
    final originalServings = _recipe.servings;
    final scaled = _scaledServings;
    if (originalServings == null || scaled == null || originalServings == 0) {
      return 1.0;
    }
    return scaled / originalServings;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scaleFactor = _scaleFactor;
    final currentServings = _scaledServings ?? _recipe.servings;
    final imageUrl = _recipe.metadata?.imageUrl;
    final tags = _recipe.metadata?.categories ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oppskrift'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Del',
            onPressed: _onTapShare,
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Dupliser',
            onPressed: _duplicateRecipe,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Slett',
            onPressed: _onTapDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              _RecipeImage(imageUrl: imageUrl),
            Text(
              _recipe.title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            RecipeOriginAndCategoryChips(recipe: _recipe),
            RecipeActionButtons(
              onEdit: _onTapEdit,
              onScale: _onTapScale,
              onConvert: () => _onTapConvert(),
            ),
            const SizedBox(height: 16),
            if (_recipe.description != null &&
                _recipe.description!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _recipe.description!,
                  style: textTheme.bodyLarge,
                ),
              ),
            if (_recipe.servings != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  currentServings == null
                      ? 'Porsjoner: ${_recipe.servings}'
                      : currentServings == _recipe.servings
                          ? 'Porsjoner: $currentServings'
                          : 'Porsjoner: $currentServings (original: ${_recipe.servings})',
                  style: textTheme.bodyMedium,
                ),
              ),
            Text(
              'Ingredienser',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._recipe.ingredients.map(
              (ingredient) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _formatIngredient(ingredient, scaleFactor),
                  style: textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Steg',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._recipe.steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${step.step}. ',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.instruction,
                            style: textTheme.bodyMedium,
                          ),
                          if (step.notes != null &&
                              step.notes!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                step.notes!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: textTheme.bodySmall?.color
                                      ?.withOpacity(0.75),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTapScale() async {
    if (_recipe.servings == null || _recipe.servings == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Denne oppskriften har ingen baseporsjoner satt for skalering ennå.'),
        ),
      );
      return;
    }

    final baseServings = _recipe.servings!;
    final initialServings = _scaledServings ?? baseServings;
    final maxServings = (baseServings * 4).round().clamp(1, 1000);

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _ScaleRecipeDialog(
          baseServings: baseServings,
          initialServings: initialServings,
          maxServings: maxServings,
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _scaledServings = result;
    });
  }

  Future<void> _onTapEdit() async {
    final updated = await Navigator.of(context).push<Recipe>(
      MaterialPageRoute(
        builder: (_) => RecipeEditScreen(recipe: _recipe),
      ),
    );

    if (!mounted || updated == null) return;

    setState(() {
      _recipe = updated;
      _scaledServings = null;
    });
  }

  Future<void> _duplicateRecipe() async {
    try {
      // Create a new recipe with copied content and new ID
      final copiedRecipe = Recipe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Kopi av ${_recipe.title}',
        description: _recipe.description,
        servings: _recipe.servings,
        ingredients: _recipe.ingredients,
        steps: _recipe.steps,
        metadata: _recipe.metadata != null
            ? RecipeMetadata(
                sourceUrl: _recipe.metadata!.sourceUrl,
                author: _recipe.metadata!.author,
                language: _recipe.metadata!.language,
                categories: List<String>.from(_recipe.metadata!.categories),
                imageUrl: _recipe.metadata!.imageUrl,
                calculatorId: _recipe.metadata!.calculatorId,
                importMethod: _recipe.metadata!.importMethod,
              )
            : null,
      );

      // Save the copied recipe
      final savedRecipe = await quantBackend.saveRecipe(copiedRecipe);

      if (!mounted) return;

      // Navigate to edit screen for the new recipe
      await Navigator.of(context).push<Recipe>(
        MaterialPageRoute(
          builder: (_) => RecipeEditScreen(recipe: savedRecipe),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke duplisere oppskrift: $e'),
        ),
      );
    }
  }

  Future<void> _onTapDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete recipe?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    try {
      await quantBackend.deleteRecipe(_recipe.id);
      if (!mounted) return;
      Navigator.of(context).pop<bool>(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete recipe: $e'),
        ),
      );
    }
  }

  String _formatIngredient(Ingredient ingredient, double scaleFactor) {
    final parts = <String>[];
    if (ingredient.amount != null) {
      final scaledAmount = ingredient.amount! * scaleFactor;
      // Show amounts without trailing .0 when possible.
      if (scaledAmount % 1 == 0) {
        parts.add(scaledAmount.toInt().toString());
      } else {
        parts.add(scaledAmount.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''));
      }
    }
    if (ingredient.unit != null && ingredient.unit!.trim().isNotEmpty) {
      parts.add(ingredient.unit!);
    }
    parts.add(ingredient.item);

    var line = parts.join(' ');
    if (ingredient.notes != null && ingredient.notes!.trim().isNotEmpty) {
      line = '$line (${ingredient.notes})';
    }
    return line;
  }

  String _buildShareText(Recipe recipe) {
    final buffer = StringBuffer();
    
    // Title
    buffer.writeln(recipe.title);
    buffer.writeln();
    
    // Description
    if (recipe.description != null && recipe.description!.trim().isNotEmpty) {
      buffer.writeln(recipe.description);
      buffer.writeln();
    }
    
    // Servings
    if (recipe.servings != null) {
      buffer.writeln('Porsjoner: ${recipe.servings}');
      buffer.writeln();
    }
    
    // Ingredients
    if (recipe.ingredients.isNotEmpty) {
      buffer.writeln('Ingredienser:');
      for (final ingredient in recipe.ingredients) {
        final parts = <String>[];
        if (ingredient.amount != null) {
          // Format amount without trailing zeros when possible
          if (ingredient.amount! % 1 == 0) {
            parts.add(ingredient.amount!.toInt().toString());
          } else {
            parts.add(ingredient.amount!.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''));
          }
        }
        if (ingredient.unit != null && ingredient.unit!.trim().isNotEmpty) {
          parts.add(ingredient.unit!);
        }
        parts.add(ingredient.item);
        
        var line = '- ${parts.join(' ')}';
        if (ingredient.notes != null && ingredient.notes!.trim().isNotEmpty) {
          line = '$line (${ingredient.notes})';
        }
        buffer.writeln(line);
      }
      buffer.writeln();
    }
    
    // Steps
    if (recipe.steps.isNotEmpty) {
      buffer.writeln('Steg:');
      for (final step in recipe.steps) {
        buffer.writeln('${step.step}. ${step.instruction}');
        if (step.notes != null && step.notes!.trim().isNotEmpty) {
          buffer.writeln('   ${step.notes}');
        }
      }
      buffer.writeln();
    }
    
    // Categories
    final categories = recipe.metadata?.categories ?? const <String>[];
    if (categories.isNotEmpty) {
      buffer.writeln('Kategorier: ${categories.join(', ')}');
    }
    
    return buffer.toString().trim();
  }

  Future<void> _onTapShare() async {
    final shareText = _buildShareText(_recipe);
    
    try {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oppskrift kopiert til utklippstavlen'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke kopiere oppskrift: $e'),
        ),
      );
    }
  }

  Future<void> _onTapConvert() async {
    // Show dialog to choose conversion direction
    final targetSystem = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konverter enheter'),
        content: const Text('Velg målesystem:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('metric'),
            child: const Text('Konverter til metrisk'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('imperial'),
            child: const Text('Konverter til imperial'),
          ),
        ],
      ),
    );

    if (targetSystem == null || !mounted) return;

    // Convert ingredients
    final convertedIngredients = _convertIngredients(
      _recipe.ingredients,
      targetSystem == 'metric',
    );

    // Show converted ingredients in bottom sheet
    if (!mounted) return;
    _showConvertedIngredients(convertedIngredients);
  }

  /// Normalizes a unit string to a canonical form for recognition.
  /// Returns null if the unit is not recognized.
  String? _normalizeUnit(String unit) {
    final normalized = unit.toLowerCase().trim();
    
    // Metric weight
    if (normalized == 'g' || normalized == 'gram' || normalized == 'gramm' || normalized == 'grams') {
      return 'g';
    }
    if (normalized == 'kg' || normalized == 'kilogram' || normalized == 'kilograms') {
      return 'kg';
    }
    
    // Imperial weight
    if (normalized == 'oz' || normalized == 'ounce' || normalized == 'ounces') {
      return 'oz';
    }
    if (normalized == 'lb' || normalized == 'lbs' || normalized == 'pound' || normalized == 'pounds') {
      return 'lb';
    }
    
    // Metric volume
    if (normalized == 'ml' || normalized == 'milliliter' || normalized == 'milliliters') {
      return 'ml';
    }
    if (normalized == 'dl') {
      return 'dl';
    }
    if (normalized == 'l' || normalized == 'liter' || normalized == 'liters' || normalized == 'litre') {
      return 'l';
    }
    
    // Imperial volume
    if (normalized == 'cup' || normalized == 'cups') {
      return 'cup';
    }
    if (normalized == 'fl oz' || normalized == 'floz') {
      return 'fl oz';
    }
    if (normalized == 'tbsp' || normalized == 'tablespoon' || normalized == 'tablespoons' || normalized == 'ss') {
      return 'tbsp';
    }
    if (normalized == 'tsp' || normalized == 'teaspoon' || normalized == 'teaspoons' || normalized == 'ts') {
      return 'tsp';
    }
    if (normalized == 'quart' || normalized == 'quarts') {
      return 'quart';
    }
    
    return null; // Unrecognized unit
  }

  /// Formats a number with smart rounding: rounds to integer if very close, otherwise 1 decimal.
  String _formatAmount(double value) {
    final rounded = (value * 10).round() / 10;
    if ((rounded - rounded.round()).abs() < 0.05) {
      return rounded.round().toString();
    }
    return rounded.toStringAsFixed(1);
  }

  List<String> _convertIngredients(List<Ingredient> ingredients, bool toMetric) {
    return ingredients.map((ingredient) {
      final amount = ingredient.amount;
      final unit = ingredient.unit?.toLowerCase().trim() ?? '';
      final item = ingredient.item;
      final notes = ingredient.notes;

      if (amount == null || unit.isEmpty) {
        // No conversion possible, return as-is
        final parts = <String>[];
        if (amount != null) {
          parts.add(_formatAmount(amount));
        }
        if (ingredient.unit != null && ingredient.unit!.isNotEmpty) {
          parts.add(ingredient.unit!);
        }
        parts.add(item);
        if (notes != null && notes.isNotEmpty) parts.add('($notes)');
        return parts.join(' ');
      }

      final normalizedUnit = _normalizeUnit(unit);
      if (normalizedUnit == null) {
        // Unrecognized unit, keep as-is
        final parts = <String>[_formatAmount(amount)];
        parts.add(ingredient.unit!);
        parts.add(item);
        if (notes != null && notes.isNotEmpty) parts.add('($notes)');
        return parts.join(' ');
      }

      double? convertedAmount;
      String? convertedUnit;

      if (toMetric) {
        // Convert from imperial to metric
        switch (normalizedUnit) {
          case 'oz':
            convertedAmount = amount * 28.35;
            convertedUnit = 'g';
            break;
          case 'lb':
            convertedAmount = amount * 0.4536; // 1 lb = 453.6 g = 0.4536 kg
            convertedUnit = 'kg';
            break;
          case 'fl oz':
            convertedAmount = amount * 29.57;
            convertedUnit = 'ml';
            break;
          case 'cup':
            convertedAmount = amount * 2.4; // 1 cup = 240 ml = 2.4 dl
            convertedUnit = 'dl';
            break;
          case 'tbsp':
            convertedAmount = amount * 15; // 1 tbsp = 15 ml
            convertedUnit = 'ml';
            break;
          case 'tsp':
            convertedAmount = amount * 5; // 1 tsp = 5 ml
            convertedUnit = 'ml';
            break;
          case 'quart':
            convertedAmount = amount * 0.946; // 1 quart = 0.946 l
            convertedUnit = 'l';
            break;
          default:
            // Should not happen, but keep as-is
            convertedAmount = amount;
            convertedUnit = ingredient.unit;
        }
      } else {
        // Convert from metric to imperial
        switch (normalizedUnit) {
          case 'g':
            convertedAmount = amount / 28.35;
            convertedUnit = 'oz';
            break;
          case 'kg':
            convertedAmount = amount / 0.4536; // 1 kg = 1/0.4536 lb ≈ 2.2046 lb
            convertedUnit = 'lb';
            break;
          case 'ml':
            convertedAmount = amount / 29.57;
            convertedUnit = 'fl oz';
            break;
          case 'dl':
            convertedAmount = amount / 2.4; // 1 dl = 100 ml, 1 cup = 240 ml, so 1 dl = 1/2.4 cup
            convertedUnit = 'cup';
            break;
          case 'l':
            convertedAmount = amount / 0.946; // 1 l = 1/0.946 quart ≈ 1.057 quart
            convertedUnit = 'quart';
            break;
          case 'tbsp':
            // tbsp is already imperial, but if converting from metric ml to tbsp
            // This case shouldn't happen in toMetric=false, but handle it
            convertedAmount = amount;
            convertedUnit = ingredient.unit;
            break;
          case 'tsp':
            // tsp is already imperial
            convertedAmount = amount;
            convertedUnit = ingredient.unit;
            break;
          default:
            // Should not happen, but keep as-is
            convertedAmount = amount;
            convertedUnit = ingredient.unit;
        }
      }

      // Format the converted amount
      final formattedAmount = _formatAmount(convertedAmount ?? amount);

      final parts = <String>[formattedAmount];
      if (convertedUnit != null) parts.add(convertedUnit);
      parts.add(item);
      if (notes != null && notes.isNotEmpty) parts.add('($notes)');

      return parts.join(' ');
    }).toList();
  }

  void _showConvertedIngredients(List<String> convertedIngredients) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Konverterte ingredienser',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: convertedIngredients.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        convertedIngredients[index],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final text = convertedIngredients.join('\n');
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Konvertert liste kopiert til utklippstavlen.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Kopier som tekst'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Ingen oppskrifter ennå',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Lag din første oppskrift, importer fra tekst, eller bruk pizzakalkulatoren.',
              style: textTheme.bodyMedium?.copyWith(
                color: textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _createNewRecipe(context),
              icon: const Icon(Icons.add),
              label: const Text('Lag første oppskrift'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ImportFromTextScreen(),
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
              onPressed: () => _openPizzaCalculator(context),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Bruk pizzakalkulator'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createNewRecipe(BuildContext context) {
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

  void _openPizzaCalculator(BuildContext context) {
    // Navigate to pizza calculator using the same pattern as calculator_category_screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PizzaCalculatorScreen(
          variantId: 'pizza-generic',
          title: 'Pizzakalkulator',
          description: 'Beregn ingredienser for pizzadeig',
        ),
      ),
    );
  }
}

/// Dialog for scaling recipe servings with slider and presets.
class _ScaleRecipeDialog extends StatefulWidget {
  const _ScaleRecipeDialog({
    required this.baseServings,
    required this.initialServings,
    required this.maxServings,
  });

  final int baseServings;
  final int initialServings;
  final int maxServings;

  @override
  State<_ScaleRecipeDialog> createState() => _ScaleRecipeDialogState();
}

class _ScaleRecipeDialogState extends State<_ScaleRecipeDialog> {
  late int _currentServings;
  late TextEditingController _textController;
  bool _isUpdatingFromSlider = false;
  bool _isUpdatingFromText = false;

  @override
  void initState() {
    super.initState();
    _currentServings = widget.initialServings;
    _textController = TextEditingController(
      text: _currentServings.toString(),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  double get _scaleFactor => _currentServings / widget.baseServings;

  void _updateServings(int newServings, {bool fromSlider = false}) {
    if (_isUpdatingFromSlider && !fromSlider) return;
    if (_isUpdatingFromText && fromSlider) return;

    final clamped = newServings.clamp(1, widget.maxServings);
    
    setState(() {
      _currentServings = clamped;
    });

    if (fromSlider) {
      _isUpdatingFromSlider = true;
      _textController.text = clamped.toString();
      _isUpdatingFromSlider = false;
    }
  }

  void _applyPreset(double multiplier) {
    final calculated = (widget.baseServings * multiplier).round();
    final newServings = calculated.clamp(1, widget.maxServings);
    _updateServings(newServings, fromSlider: true);
  }

  void _onTextChanged(String value) {
    if (_isUpdatingFromSlider) return;

    if (value.isEmpty) {
      // Allow empty input while typing
      return;
    }

    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0 && parsed <= widget.maxServings) {
      _isUpdatingFromText = true;
      _updateServings(parsed);
      _isUpdatingFromText = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scaleFactor = _scaleFactor;
    final scaleText = scaleFactor == 1.0
        ? '1× (original)'
        : scaleFactor < 1.0
            ? '${scaleFactor.toStringAsFixed(1)}×'
            : '${scaleFactor.toStringAsFixed(1)}×';

    return AlertDialog(
      title: const Text('Skaler oppskrift'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview text
            Text(
              'Skalerer fra ${widget.baseServings} til $_currentServings porsjoner ($scaleText)',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: textTheme.bodyMedium?.color?.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 24),
            // Slider with larger thumb for mobile
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 20,
                ),
              ),
              child: Slider(
                value: _currentServings.toDouble().clamp(1.0, widget.maxServings.toDouble()),
                min: 1.0,
                max: widget.maxServings.toDouble(),
                divisions: widget.maxServings > 1 ? widget.maxServings - 1 : null,
                label: _currentServings.toString(),
                onChanged: (value) {
                  final rounded = value.round();
                  _updateServings(rounded, fromSlider: true);
                },
              ),
            ),
            const SizedBox(height: 12),
            // Preset buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PresetButton(
                  label: '×1',
                  onPressed: () => _applyPreset(1.0),
                  isActive: scaleFactor == 1.0,
                ),
                _PresetButton(
                  label: '×2',
                  onPressed: () => _applyPreset(2.0),
                  isActive: (scaleFactor - 2.0).abs() < 0.05,
                ),
                _PresetButton(
                  label: '×3',
                  onPressed: () => _applyPreset(3.0),
                  isActive: (scaleFactor - 3.0).abs() < 0.05,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Text field
            TextField(
              controller: _textController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Målporsjoner',
                border: const OutlineInputBorder(),
                helperText: 'Skriv inn heltall for porsjoner (1-${widget.maxServings})',
                suffixText: _currentServings > 0 ? 'porsjoner' : null,
              ),
              onChanged: _onTextChanged,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: _currentServings > 0 && _currentServings <= widget.maxServings
              ? () {
                  Navigator.of(context).pop(_currentServings);
                }
              : null,
          child: const Text('Bruk'),
        ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        foregroundColor: isActive
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(60, 36),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _RecipeImage extends StatefulWidget {
  const _RecipeImage({required this.imageUrl});

  final String imageUrl;

  @override
  State<_RecipeImage> createState() => _RecipeImageState();
}

class _RecipeImageState extends State<_RecipeImage> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, _, __) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                  });
                }
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
