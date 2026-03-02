import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../backend/quant_backend.dart';
import '../models/recipe.dart';
import 'recipe_edit_screen.dart';
import '../auth/auth_expired_handler.dart';
import '../features/calculators/screens/calculators_screen.dart';
import 'import_recipe_screen.dart';
import 'create_recipe_screen.dart';


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

String? _importLabel(String? importMethod) {
  if (importMethod == null) return null;

  switch (importMethod) {
    case 'calculator':
      return 'Fra pizzakalkulator';

    case 'plain_text':
    case 'text':
    case 'stub':
      return 'Importert fra tekst';

    case 'url':
      return 'Importert fra URL';

    case 'manual':
      return 'Manuelt opprettet';

    default:
      return null;
  }
}


/// Reusable widget that displays import method and category chips for a recipe.
class RecipeOriginAndCategoryChips extends StatelessWidget {
  const RecipeOriginAndCategoryChips({
    super.key,
    required this.recipe,
  });

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final importLabel = _importLabel(recipe.metadata?.importMethod);
    final categories = recipe.metadata?.categories ?? const <String>[];
    final hasChips = importLabel != null || categories.isNotEmpty;

    if (!hasChips) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (importLabel != null)
            Chip(
              label: Text(importLabel),
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

enum _SharedFilter { all, mine, sharedWithMe }

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  String _searchQuery = '';
  String? _selectedTag;
  RecipeOriginFilter _originFilter = RecipeOriginFilter.all;
  late final TextEditingController _searchController;
  late Future<List<Recipe>> _recipesFuture;
  RecipeSortMode _sortMode = RecipeSortMode.titleAsc;
  _SharedFilter _sharedFilter = _SharedFilter.all;
  Timer? _searchDebounce;
  bool _isAdmin = false;
  List<Recipe>? _cachedRecipes;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _searchQuery);
    // Fetch recipes once; filtering is done client-side without reloading.
    _recipesFuture = quantBackend.getAllRecipes();
    // Determine if current user is admin (read-only in app).
    quantBackend.getMe().then((me) {
      final username = (me['username'] ?? '').toString().toLowerCase().trim();
      if (!mounted) return;
      setState(() {
        _isAdmin = username == 'admin';
      });
    }).catchError((_) {
      // ignore – default false
    });
  }

  void _reloadRecipes() {
    setState(() {
      _cachedRecipes = null;
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
          PopupMenuButton<RecipeSortMode>(
            tooltip: 'Sorter',
            icon: const Icon(Icons.sort),
            onSelected: (mode) {
              setState(() {
                _sortMode = mode;
              });
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem<RecipeSortMode>(
                value: RecipeSortMode.recentlyUsed,
                checked: _sortMode == RecipeSortMode.recentlyUsed,
                child: const Text('Sist brukt'),
              ),
              CheckedPopupMenuItem<RecipeSortMode>(
                value: RecipeSortMode.mostUsed,
                checked: _sortMode == RecipeSortMode.mostUsed,
                child: const Text('Mest brukt'),
              ),
              CheckedPopupMenuItem<RecipeSortMode>(
                value: RecipeSortMode.recentlyAdded,
                checked: _sortMode == RecipeSortMode.recentlyAdded,
                child: const Text('Nylig lagt til'),
              ),
              CheckedPopupMenuItem<RecipeSortMode>(
                value: RecipeSortMode.recentlyEdited,
                checked: _sortMode == RecipeSortMode.recentlyEdited,
                child: const Text('Sist endret'),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem<RecipeSortMode>(
                value: RecipeSortMode.favoriteFirst,
                checked: _sortMode == RecipeSortMode.favoriteFirst,
                child: Row(
                  children: const [
                    Icon(Icons.star, size: 18, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Favoritt først'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem<RecipeSortMode>(
                value: RecipeSortMode.titleAsc,
                checked: _sortMode == RecipeSortMode.titleAsc,
                child: const Text('Tittel A–Å'),
              ),
              CheckedPopupMenuItem<RecipeSortMode>(
                value: RecipeSortMode.titleDesc,
                checked: _sortMode == RecipeSortMode.titleDesc,
                child: const Text('Tittel Å–A'),
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
            // Auth expired → send til login
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await maybeHandleAuthExpired(context, snapshot.error!);
            });

            // Vis en “tom” placeholder mens vi navigerer
            return const SizedBox.shrink();
          }

          _cachedRecipes ??= (snapshot.data ?? const []);
          final recipes = _cachedRecipes ?? const <Recipe>[];

          if (recipes.isEmpty) {
            return _EmptyState();
          }

          final allTags = <String>{
            for (final r in recipes) ...?r.metadata?.categories,
          }.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          // Apply origin filter first
          var filtered = recipes;
          String _norm(String? s) => (s ?? '').trim().toLowerCase();

          switch (_originFilter) {
            case RecipeOriginFilter.manual:
              filtered = recipes.where((r) {
                final method = _norm(r.metadata?.importMethod);
                return method.isEmpty || method == 'manual';
              }).toList();
              break;

            case RecipeOriginFilter.pizzaCalculator:
              filtered = recipes.where((r) {
                final method = _norm(r.metadata?.importMethod);
                return method == 'calculator';
              }).toList();
              break;

            case RecipeOriginFilter.imported:
              filtered = recipes.where((r) {
                final method = _norm(r.metadata?.importMethod);
                return method == 'text' ||
                    method == 'plain_text' ||
                    method == 'stub' ||
                    method == 'url' ||
                    method == 'image';
              }).toList();
              break;

            case RecipeOriginFilter.all:
              break;
          }

          // Apply shared filter (mine vs delt med meg)
          filtered = filtered.where((r) {
            final sharedFrom = (r.sharedFromUsername ?? '').trim(); // evt sharedFromUsername hvis du har det
            final isSharedWithMe = sharedFrom.isNotEmpty;

            switch (_sharedFilter) {
              case _SharedFilter.all:
                return true;
              case _SharedFilter.mine:
                return !isSharedWithMe;
              case _SharedFilter.sharedWithMe:
                return isSharedWithMe;
            }
          }).toList();

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
// Apply sorting.
// Apply sorting.
          filtered.sort((a, b) {
            int cmpBool(bool aVal, bool bVal) {
              if (aVal == bVal) return 0;
              return aVal ? -1 : 1;
            }

            int cmpTitle(Recipe ra, Recipe rb, {required bool asc}) {
              final at = ra.title.toLowerCase();
              final bt = rb.title.toLowerCase();
              final cmp = at.compareTo(bt);
              return asc ? cmp : -cmp;
            }

            // 🔥 Sticky pinned — ALLTID først
            final pinnedCompare = cmpBool(a.isPinned, b.isPinned);
            if (pinnedCompare != 0) return pinnedCompare;

            // Resten styres av valgt sortering
            switch (_sortMode) {
              case RecipeSortMode.recentlyUsed: {
                // NULL = gammel → nederst (nulls last), desc
                final aT = a.lastViewedAt;
                final bT = b.lastViewedAt;

                if (aT == null && bT == null) return cmpTitle(a, b, asc: true);
                if (aT == null) return 1;
                if (bT == null) return -1;

                return bT.compareTo(aT);
              }

              case RecipeSortMode.mostUsed: {
                // NULL viewCount behandles som 0
                final av = a.viewCount ?? 0;
                final bv = b.viewCount ?? 0;

                if (av != bv) return bv.compareTo(av);
                return cmpTitle(a, b, asc: true);
              }

              case RecipeSortMode.recentlyAdded: {
                // NULL = gammel → nederst (nulls last), desc
                final aT = a.createdAt;
                final bT = b.createdAt;

                if (aT == null && bT == null) return cmpTitle(a, b, asc: true);
                if (aT == null) return 1;
                if (bT == null) return -1;

                return bT.compareTo(aT);
              }

              case RecipeSortMode.recentlyEdited: {
                // NULL = gammel → nederst (nulls last), desc
                final aT = a.updatedAt;
                final bT = b.updatedAt;

                if (aT == null && bT == null) return cmpTitle(a, b, asc: true);
                if (aT == null) return 1;
                if (bT == null) return -1;

                return bT.compareTo(aT);
              }

              case RecipeSortMode.favoriteFirst: {
                final fav = cmpBool(a.isFavorite, b.isFavorite);
                if (fav != 0) return fav;
                return cmpTitle(a, b, asc: true);
              }

              case RecipeSortMode.titleAsc:
                return cmpTitle(a, b, asc: true);

              case RecipeSortMode.titleDesc:
                return cmpTitle(a, b, asc: false);
            }
          });

          final hasActiveFilters =
              _searchQuery.trim().isNotEmpty ||
                  _selectedTag != null ||
                  _originFilter != RecipeOriginFilter.all ||
                  _sharedFilter != _SharedFilter.all;

          return ListView.separated(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 96,
            ),
            itemCount: filtered.length + 1,
            separatorBuilder: (context, index) =>
                index == 0 ? const SizedBox(height: 12) : const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    //Row(
                    //  crossAxisAlignment: CrossAxisAlignment.start,
                    //  children: [
                    //    Expanded(
                    //      child: PopupMenuButton<_SharedFilter>(
                    //        tooltip: 'Vis',
                    //        onSelected: (f) => setState(() => _sharedFilter = f),
                    //        itemBuilder: (context) => const [
                    //          PopupMenuItem(
                    //            value: _SharedFilter.all,
                    //            child: Text('Vis: Alle'),
                    //          ),
                    //          PopupMenuItem(
                    //            value: _SharedFilter.mine,
                    //            child: Text('Vis: Mine'),
                    //          ),
                    //          PopupMenuItem(
                    //            value: _SharedFilter.sharedWithMe,
                    //            child: Text('Vis: Delt med meg'),
                    //          ),
                    //        ],
                    //        child: Align(
                    //          alignment: Alignment.centerLeft,
                    //          child: Chip(
                    //            label: Text('Vis: ${_sharedLabel(_sharedFilter)}  ▾'),
                    //          ),
                    //        ),
                    //      ),
                    //    ),
                    //    const SizedBox(width: 8),
                    //    PopupMenuButton<RecipeOriginFilter>(
                    //      tooltip: 'Kilde',
                    //      onSelected: (filter) => setState(() => _originFilter = filter),
                    //      itemBuilder: (context) => const [
                    //        PopupMenuItem(
                    //          value: RecipeOriginFilter.all,
                    //          child: Text('Kilde: Alle'),
                    //        ),
                    //        PopupMenuItem(
                    //          value: RecipeOriginFilter.manual,
                    //          child: Text('Kilde: Manuell'),
                    //        ),
                    //        PopupMenuItem(
                    //          value: RecipeOriginFilter.imported,
                    //          child: Text('Kilde: Import'),
                    //        ),
                    //        PopupMenuItem(
                    //          value: RecipeOriginFilter.pizzaCalculator,
                    //          child: Text('Kilde: Kalkulator'),
                    //        ),
                    //      ],
                    //      child: Row(
                    //        mainAxisSize: MainAxisSize.min,
                    //        children: [
                    //          Chip(
                    //            label: Text('Kilde: ${_originLabel(_originFilter)}  ▾'),
                    //          ),
                    //          const SizedBox(width: 8),
                    //          ActionChip(
                    //            avatar: const Icon(Icons.filter_list, size: 18),
                    //            label: const Text('Filter'),
                    //            onPressed: () => _showTagFilterSheet(allTags),
                    //          ),
                    //        ],
                    //      ),
                    //    ),
                    //  ],
                    //),
                    Row(
                      children: [
                        Expanded(
                          child: _RecipeSearchBar(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Filtre',
                          icon: const Icon(Icons.tune),
                          onPressed: () => _showFiltersSheet(allTags),
                        ),
                      ],
                    ),
                    //const SizedBox(height: 8),
                    //_RecipeSearchBar(
                    //  controller: _searchController,
                    //  onChanged: _onSearchChanged,
                    //),
                    const SizedBox(height: 8),
                    if (hasActiveFilters) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _selectedTag = null;
                            _originFilter = RecipeOriginFilter.all;
                            _sharedFilter = _SharedFilter.all; // <-- LEGG TIL
                            _searchController.clear();
                          });
                        },
                        child: const Text('Nullstill filtre'),
                      ),
                    ],
                    if (filtered.isEmpty)
                      Text(
                        'Ingen oppskrifter matcher filtrene dine.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 12),
                  ],
                );
              }

              if (filtered.isEmpty) {
                return const SizedBox.shrink();
              }

              final recipe = filtered[index - 1];
              return _RecipeListTile(
                recipe: recipe,
                canMutate: !_isAdmin,
                onRecipeChanged: (updated) {
                  setState(() {
                    _cachedRecipes = (_cachedRecipes ?? recipes).map((r) {
                      return r.id == updated.id ? updated : r;
                    }).toList();
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
  String _originLabel(RecipeOriginFilter f) {
    switch (f) {
      case RecipeOriginFilter.all:
        return 'Alle';
      case RecipeOriginFilter.manual:
        return 'Manuell';
      case RecipeOriginFilter.imported:
        return 'Import';
      case RecipeOriginFilter.pizzaCalculator:
        return 'Kalkulator';
    }
  }

  void _showFiltersSheet(List<String> allTags) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filtre',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- VIS (Alle / Mine / Delt) ----
                  Text(
                    'Vis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Alle'),
                        selected: _sharedFilter == _SharedFilter.all,
                        onSelected: (_) {
                          setState(() => _sharedFilter = _SharedFilter.all);
                          Navigator.pop(context);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Mine'),
                        selected: _sharedFilter == _SharedFilter.mine,
                        onSelected: (_) {
                          setState(() => _sharedFilter = _SharedFilter.mine);
                          Navigator.pop(context);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Delt med meg'),
                        selected: _sharedFilter == _SharedFilter.sharedWithMe,
                        onSelected: (_) {
                          setState(() => _sharedFilter = _SharedFilter.sharedWithMe);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ---- KILDE (Alle/Manuell/Import/Kalkulator) ----
                  Text(
                    'Kilde',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Alle'),
                        selected: _originFilter == RecipeOriginFilter.all,
                        onSelected: (_) {
                          setState(() => _originFilter = RecipeOriginFilter.all);
                          Navigator.pop(context);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Manuell'),
                        selected: _originFilter == RecipeOriginFilter.manual,
                        onSelected: (_) {
                          setState(() => _originFilter = RecipeOriginFilter.manual);
                          Navigator.pop(context);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Import'),
                        selected: _originFilter == RecipeOriginFilter.imported,
                        onSelected: (_) {
                          setState(() => _originFilter = RecipeOriginFilter.imported);
                          Navigator.pop(context);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Kalkulator'),
                        selected: _originFilter == RecipeOriginFilter.pizzaCalculator,
                        onSelected: (_) {
                          setState(() => _originFilter = RecipeOriginFilter.pizzaCalculator);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ---- TAG (valgfri, single-select) ----
                  Text(
                    'Tag',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (allTags.isEmpty)
                    Text(
                      'Ingen tagger funnet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Alle'),
                          selected: _selectedTag == null,
                          onSelected: (_) {
                            setState(() => _selectedTag = null);
                            Navigator.pop(context);
                          },
                        ),
                        ...allTags.map((tag) {
                          final selected = _selectedTag == tag;
                          return ChoiceChip(
                            label: Text(tag),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _selectedTag = selected ? null : tag;
                              });
                              Navigator.pop(context); // <- viktig
                            },
                          );
                        }),
                      ],
                    ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _selectedTag = null;
                              _originFilter = RecipeOriginFilter.all;
                              _sharedFilter = _SharedFilter.all;
                              _searchController.clear();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Nullstill'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Ferdig'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _sharedLabel(_SharedFilter f) {
    switch (f) {
      case _SharedFilter.all:
        return 'Alle';
      case _SharedFilter.mine:
        return 'Mine';
      case _SharedFilter.sharedWithMe:
        return 'Delt med meg';
    }
  }

  void _showTagFilterSheet(List<String> allTags) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrer på tag',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allTags.map((tag) {
                    final selected = _selectedTag == tag;
                    return ChoiceChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedTag = selected ? null : tag;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
                if (_selectedTag != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedTag = null);
                      Navigator.pop(context);
                    },
                    child: const Text('Fjern tag-filter'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    if (_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin-bruker kan ikke endre oppskrifter.')),
      );
      return;
    }

    final next = !recipe.isFavorite;

    final updated = Recipe(
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      servings: recipe.servings,
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      metadata: recipe.metadata,
      sharedFromUsername: recipe.sharedFromUsername,
      isFavorite: next,
      isPinned: recipe.isPinned,
      favoritedAt: next ? DateTime.now() : null,
      pinnedAt: recipe.pinnedAt,
    );

    try {
      await quantBackend.saveRecipe(updated);
      _reloadRecipes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke lagre favoritt: $e')),
      );
    }
  }

  Future<void> _togglePinned(Recipe recipe) async {
    if (_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin-bruker kan ikke endre oppskrifter.')),
      );
      return;
    }

    final next = !recipe.isPinned;

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
      isPinned: next,
      favoritedAt: recipe.favoritedAt,
      pinnedAt: next ? DateTime.now() : null,
    );

    try {
      await quantBackend.saveRecipe(updated);
      _reloadRecipes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke lagre festet: $e')),
      );
    }
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
  recentlyUsed,   // lastViewedAt desc
  mostUsed,       // viewCount desc
  recentlyAdded,  // createdAt desc
  recentlyEdited, // updatedAt desc
  favoriteFirst,  // favorite desc
  titleAsc,       // A–Å
  titleDesc,      // Å–A
}

enum RecipeOriginFilter {
  all,
  manual,
  pizzaCalculator,
  imported,
}

//class _OriginFilterRow extends StatelessWidget {
//  const _OriginFilterRow({
//    required this.selectedFilter,
//    required this.onFilterSelected,
//  });
//
//  final RecipeOriginFilter selectedFilter;
//  final ValueChanged<RecipeOriginFilter> onFilterSelected;
//
//  @override
//  Widget build(BuildContext context) {
//    return SingleChildScrollView(
//      scrollDirection: Axis.horizontal,
//      child: Row(
//        children: [
//          ChoiceChip(
//            label: const Text('Alle'),
//            selected: selectedFilter == RecipeOriginFilter.all,
//            onSelected: (_) => onFilterSelected(RecipeOriginFilter.all),
//          ),
//          const SizedBox(width: 8),
//          ChoiceChip(
//            label: const Text('Manuelt'),
//            selected: selectedFilter == RecipeOriginFilter.manual,
//            onSelected: (_) => onFilterSelected(RecipeOriginFilter.manual),
//          ),
//          const SizedBox(width: 8),
//          ChoiceChip(
//            label: const Text('Pizzakalkulator'),
//            selected: selectedFilter == RecipeOriginFilter.pizzaCalculator,
//            onSelected: (_) => onFilterSelected(RecipeOriginFilter.pizzaCalculator),
//          ),
//          const SizedBox(width: 8),
//          ChoiceChip(
//            label: const Text('Importert'),
//            selected: selectedFilter == RecipeOriginFilter.imported,
//            onSelected: (_) => onFilterSelected(RecipeOriginFilter.imported),
//          ),
//        ],
//      ),
//    );
//  }
//}

//class _TagFilterRow extends StatelessWidget {
//  const _TagFilterRow({
//    required this.tags,
//    required this.selectedTag,
//    required this.onTagSelected,
//  });
//
//  final List<String> tags;
//  final String? selectedTag;
//  final ValueChanged<String> onTagSelected;
//
//  @override
//  Widget build(BuildContext context) {
//    if (tags.isEmpty) {
//      return const SizedBox.shrink();
//    }
//
//    return SingleChildScrollView(
//      scrollDirection: Axis.horizontal,
//      child: Row(
//        children: [
//          for (final tag in tags) ...[
//            ChoiceChip(
//              label: Text(tag),
//              selected: selectedTag != null &&
//                  selectedTag!.toLowerCase() == tag.toLowerCase(),
//              onSelected: (_) => onTagSelected(tag),
//            ),
//            const SizedBox(width: 8),
//          ],
//        ],
//      ),
//    );
//  }
//}

String _formatTags(List<String> tags) {
  final cleaned = tags
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();
  if (cleaned.isEmpty) return '';
  return cleaned.join(' • ');
}

Widget _buildRecipeLeadingImage(BuildContext context, String? imageUrl) {
  final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
  final borderRadius = BorderRadius.circular(12);
  const imageSize = 56.0;

  if (hasImage) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        imageUrl!,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) {
          return Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: Theme.of(context).dividerColor),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_outlined,
              size: 20,
            ),
          );
        },
      ),
    );
  }

  // Placeholder for oppskrifter uten bilde
  return ClipRRect(
    borderRadius: borderRadius,
    child: Container(
      width: imageSize,
      height: imageSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 20,
      ),
    ),
  );
}

class _RecipeListTile extends StatefulWidget {
  const _RecipeListTile({
    required this.recipe,
    required this.onRecipeChanged,
    required this.canMutate,
  });

  final Recipe recipe;
  final ValueChanged<Recipe> onRecipeChanged; // oppdaterer lista lokalt
  final bool canMutate;

  @override
  State<_RecipeListTile> createState() => _RecipeListTileState();
}

class _RecipeListTileState extends State<_RecipeListTile> {
  late bool _isFavorite;
  late bool _isPinned;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.recipe.isFavorite;
    _isPinned = widget.recipe.isPinned;
  }

  @override
  void didUpdateWidget(covariant _RecipeListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe.id != widget.recipe.id) {
      _isFavorite = widget.recipe.isFavorite;
      _isPinned = widget.recipe.isPinned;
    }
  }

  Future<void> _save({required bool favorite, required bool pinned}) async {
    final now = DateTime.now();

    final updated = Recipe(
      id: widget.recipe.id,
      title: widget.recipe.title,
      description: widget.recipe.description,
      servings: widget.recipe.servings,
      ingredients: widget.recipe.ingredients,
      steps: widget.recipe.steps,
      metadata: widget.recipe.metadata,
      sharedFromUsername: widget.recipe.sharedFromUsername,
      isFavorite: favorite,
      isPinned: pinned,
      favoritedAt: favorite ? (widget.recipe.favoritedAt ?? now) : null,
      pinnedAt: pinned ? (widget.recipe.pinnedAt ?? now) : null,
    );

    // Optimistic UI: oppdater parent sin liste uten full reload
    widget.onRecipeChanged(updated);

    try {
      await quantBackend.saveRecipe(updated);
    } catch (e) {
      // Revert visuelt ved å oppdatere parent tilbake til original
      widget.onRecipeChanged(widget.recipe);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunne ikke lagre: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (!widget.canMutate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin-bruker kan ikke endre oppskrifter.')),
      );
      return;
    }
    if (_isSaving) return;

    final next = !_isFavorite;
    setState(() {
      _isFavorite = next;
      _isSaving = true;
    });

    await _save(favorite: next, pinned: _isPinned);

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _togglePinned() async {
    if (!widget.canMutate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin-bruker kan ikke endre oppskrifter.')),
      );
      return;
    }
    if (_isSaving) return;

    final next = !_isPinned;
    setState(() {
      _isPinned = next;
      _isSaving = true;
    });

    await _save(favorite: _isFavorite, pinned: next);

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final textTheme = Theme.of(context).textTheme;
    final servingsText =
    recipe.servings != null ? '${recipe.servings} porsjoner' : null;
    final tags = recipe.metadata?.categories ?? const <String>[];
    final imageUrl = recipe.metadata?.imageUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: _buildRecipeLeadingImage(context, imageUrl),
            title: Text(
              recipe.title,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recipe.description != null && recipe.description!.trim().isNotEmpty)
                  Text(
                    recipe.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (servingsText != null) ...[
                  const SizedBox(height: 4),
                  Text(servingsText),
                ],
                if (recipe.sharedFromUsername != null &&
                    recipe.sharedFromUsername!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Delt av ${recipe.sharedFromUsername}',
                      style: textTheme.bodySmall?.copyWith(
                        color: textTheme.bodySmall?.color?.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
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
              final result = await Navigator.of(context).push<dynamic>(
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(recipe: recipe),
                ),
              );

              if (!mounted) return;

              // Hvis detail returnerer oppdatert Recipe (etter markViewed),
              // så oppdaterer vi parent sin cache via callback.
              if (result is Recipe) {
                widget.onRecipeChanged(result);
                return;
              }

              // Backward-compat: hvis detail returnerer bool (f.eks delete),
              // gjør ingenting her (parent håndterer delete via reload/andre flows).
              // Hvis du vil støtte delete lokalt senere, kan vi utvide callbacken.
            },
          ),

          // Badges: nederst til høyre (pent og ikke i veien)
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.canMutate ? _togglePinned : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.push_pin,
                      size: 18,
                      color: _isPinned
                          ? Colors.red
                          : Theme.of(context).iconTheme.color?.withOpacity(0.30),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.canMutate ? _toggleFavorite : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.star,
                      size: 18,
                      color: _isFavorite
                          ? Colors.amber
                          : Theme.of(context).iconTheme.color?.withOpacity(0.30),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: _isSaving
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



enum _RecipeMenuAction { shareInApp, shareAsText, duplicate, delete }


class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _ShareDialogResult {
  final String username;
  final String? message;

  _ShareDialogResult({required this.username, this.message});
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;
  int? _scaledServings;
  bool _keepScreenOn = false;

  void _popWithRecipe() {
    // Return updated recipe back to the list so sorting (Sist brukt / Mest brukt)
    // can refresh without a full reload.
    if (!Navigator.of(context).canPop()) return;
    Navigator.of(context).pop<Recipe>(_recipe);
  }

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _registerView();
  }

  Future<void> _registerView() async {
    // Oppdater lokalt først, så "Sist brukt" / "Mest brukt" blir riktig
    // når vi returnerer _recipe til lista ved back.
    final now = DateTime.now();

    if (mounted) {
      setState(() {
        _recipe = Recipe(
          id: _recipe.id,
          title: _recipe.title,
          description: _recipe.description,
          servings: _recipe.servings,
          ingredients: _recipe.ingredients,
          steps: _recipe.steps,
          metadata: _recipe.metadata,
          sharedFromUsername: _recipe.sharedFromUsername,
          isFavorite: _recipe.isFavorite,
          isPinned: _recipe.isPinned,
          favoritedAt: _recipe.favoritedAt,
          pinnedAt: _recipe.pinnedAt,

          // 👇 nye sorteringsfelt
          createdAt: _recipe.createdAt,
          updatedAt: _recipe.updatedAt,
          lastViewedAt: now,
          viewCount: (_recipe.viewCount ?? 0) + 1,
        );
      });
    }

    // Backend-kall (feil her skal ikke ødelegge UI-sortering)
    try {
      await quantBackend.markViewed(_recipe.id);
    } catch (_) {
      // ignore
    }
  }

  void _toggleKeepScreenOn() async {
    final next = !_keepScreenOn;

    setState(() {
      _keepScreenOn = next;
    });

    if (next) {
      await WakelockPlus.enable();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skjermen holdes på')),
      );
    } else {
      await WakelockPlus.disable();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Normal hvilemodus aktiv')),
      );
    }
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

    final groupedIngredients = <String?, List<Ingredient>>{};
    for (final ing in _recipe.ingredients) {
      groupedIngredients.putIfAbsent(ing.section, () => []).add(ing);
    }

    final entries = groupedIngredients.entries.toList()
      ..sort((a, b) {
        if (a.key == null) return -1; // uten section først
        if (b.key == null) return 1;
        return a.key!.toLowerCase().compareTo(b.key!.toLowerCase());
      });

    return WillPopScope(
        onWillPop: () async {
          _popWithRecipe();
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Oppskrift'),
            leading: BackButton(onPressed: _popWithRecipe),
            actions: [
              IconButton(
                tooltip: 'Hold skjerm på',
                icon: Icon(
                  Icons.wb_sunny_outlined,
                  color: _keepScreenOn
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: _toggleKeepScreenOn,
              ),
              PopupMenuButton<_RecipeMenuAction>(
                tooltip: 'Meny',
                onSelected: (action) async {
                  switch (action) {
                    case _RecipeMenuAction.shareInApp:
                      await _onTapShareInApp();
                      break;

                    case _RecipeMenuAction.shareAsText:
                      await _onTapShare();
                      break;

                    case _RecipeMenuAction.duplicate:
                      await _duplicateRecipe();
                      break;

                    case _RecipeMenuAction.delete:
                      await _onTapDelete();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _RecipeMenuAction.shareInApp,
                    child: Text('Del i app'),
                  ),
                  PopupMenuItem(
                    value: _RecipeMenuAction.shareAsText,
                    child: Text('Del som tekst'),
                  ),
                  PopupMenuItem(
                    value: _RecipeMenuAction.duplicate,
                    child: Text('Dupliser'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _RecipeMenuAction.delete,
                    child: Text('Slett'),
                  ),
                ],
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
            if ((_recipe.metadata?.sourceUrl ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showSourceUrlSheet(_recipe.metadata!.sourceUrl!.trim()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link,
                          size: 16,
                          color: textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kilde (trykk for å se/kopiere)',
                            style: textTheme.bodyMedium?.copyWith(
                              color: textTheme.bodyMedium?.color?.withOpacity(0.85),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
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
                          : 'Porsjoner: $currentServings (opprinnelig: ${_recipe.servings})',
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
            ...entries.expand((entry) {
              final section = entry.key;
              final ingredients = entry.value;

              return [
                if (section != null && section.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 6),
                    child: Text(
                      section,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ...ingredients.map(
                      (ingredient) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _formatIngredient(ingredient, scaleFactor),
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ),
              ];
            }).toList(),

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
        ),
    );
  }

  Future<void> _onTapShareInApp() async {
    final result = await showDialog<_ShareDialogResult>(
      context: context,
      builder: (dialogContext) {
        final usernameController = TextEditingController();
        final messageController = TextEditingController();

        return AlertDialog(
          title: const Text('Del i app'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Brukernavn',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Melding (valgfri)',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () {
                final username = usernameController.text.trim();
                final message = messageController.text.trim();

                if (username.isEmpty) {
                  Navigator.of(dialogContext).pop(null);
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _ShareDialogResult(
                    username: username,
                    message: message.isEmpty ? null : message,
                  ),
                );
              },
              child: const Text('Del'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    try {
      await quantBackend.shareRecipe(
        _recipe.id,
        result.username,
        message: result.message,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oppskrift delt med ${result.username}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke dele: $e')),
      );
    }
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

  void _showSourceUrlSheet(String url) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kilde',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                url,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Lenke kopiert')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Kopier'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Lukk'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
          title: const Text('Slett oppskrift?'),
          content: const Text('Dette kan ikke angres.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Slett'),
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
          content: Text('Kunne ikke slette oppskrift: $e'),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
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
              'Lag din første oppskrift, importer, eller bruk et verktøy.',
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
              onTap: () => _createNewRecipe(context),
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
              icon: Icons.calculate_outlined,
              title: 'Lag fra verktøy',
              subtitle: 'Bruk kalkulator og lagre resultatet.',
              onTap: () => _openTools(context),
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

  void _openTools(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CalculatorsScreen(),
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
        ? '1× (opprinnelig)'
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _pressed
                ? Theme.of(context).colorScheme.primary.withOpacity(0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
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
                        color: enabled
                            ? textTheme.titleMedium?.color
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: (enabled
                            ? textTheme.bodySmall?.color
                            : Theme.of(context).disabledColor)
                            ?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                    : Theme.of(context).disabledColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
