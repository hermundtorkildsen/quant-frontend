import 'package:flutter/material.dart';

import '../backend/quant_backend.dart';
import '../models/recipe.dart';
import 'my_recipes_screen.dart';

/// Screen for editing or creating a recipe.
///
/// If [isImportReview] is true, the save button will be labeled "Save" instead of "Update".
class RecipeEditScreen extends StatefulWidget {
  const RecipeEditScreen({
    super.key,
    required this.recipe,
    this.isImportReview = false,
  });

  final Recipe recipe;
  final bool isImportReview;

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _servingsController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _tagsController;

  late List<_EditableIngredient> _editableIngredients;
  late List<_EditableStep> _editableSteps;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _descriptionController =
        TextEditingController(text: widget.recipe.description ?? '');
    _servingsController = TextEditingController(
        text: widget.recipe.servings?.toString() ?? '');
    _imageUrlController = TextEditingController(
        text: widget.recipe.metadata?.imageUrl ?? '');
    _tagsController = TextEditingController(
        text: (widget.recipe.metadata?.categories ?? []).join(', '));

    // Add listeners to track changes
    _titleController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);
    _servingsController.addListener(_markAsChanged);
    _imageUrlController.addListener(_markAsChanged);
    _tagsController.addListener(_markAsChanged);

    _editableIngredients = widget.recipe.ingredients
        .map((ing) => _EditableIngredient(
              amount: ing.amount?.toString() ?? '',
              unit: ing.unit ?? '',
              item: ing.item,
              notes: ing.notes ?? '',
            ))
        .toList();

    _editableSteps = widget.recipe.steps
        .map((step) => _EditableStep(
              stepNumber: step.step,
              instruction: step.instruction,
              notes: step.notes ?? '',
            ))
        .toList();
  }

  @override
  void dispose() {
    _titleController.removeListener(_markAsChanged);
    _descriptionController.removeListener(_markAsChanged);
    _servingsController.removeListener(_markAsChanged);
    _imageUrlController.removeListener(_markAsChanged);
    _tagsController.removeListener(_markAsChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _servingsController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forkast endringer?'),
        content: const Text(
          'Du har ulagrede endringer. Vil du forkaste dem?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Forkast'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Build ingredients from editable model
      final ingredients = _editableIngredients
          .map((editable) => Ingredient(
                amount: double.tryParse(editable.amount.trim()),
                unit: editable.unit.trim().isEmpty
                    ? null
                    : editable.unit.trim(),
                item: editable.item.trim(),
                notes: editable.notes.trim().isEmpty
                    ? null
                    : editable.notes.trim(),
              ))
          .toList();

      // Build steps from editable model
      final steps = _editableSteps
          .asMap()
          .entries
          .map((entry) => RecipeStep(
                step: entry.key + 1,
                instruction: entry.value.instruction.trim(),
                notes: entry.value.notes.trim().isEmpty
                    ? null
                    : entry.value.notes.trim(),
              ))
          .toList();

      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // Build metadata
      final existingMetadata = widget.recipe.metadata;
      final metadata = RecipeMetadata(
        sourceUrl: existingMetadata?.sourceUrl,
        author: existingMetadata?.author,
        language: existingMetadata?.language,
        categories: tags,
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        calculatorId: existingMetadata?.calculatorId,
        importMethod: existingMetadata?.importMethod,
      );

      final updatedRecipe = Recipe(
        id: widget.recipe.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        servings: int.tryParse(_servingsController.text.trim()) ?? 1,
        ingredients: ingredients,
        steps: steps,
        metadata: metadata,
      );

      final savedRecipe = await quantBackend.saveRecipe(updatedRecipe);

      if (!mounted) return;

      setState(() {
        _hasUnsavedChanges = false;
      });

      // Navigate to recipe detail screen, replacing the edit screen
      // and clearing navigation history to prevent returning to import flow
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: savedRecipe),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke lagre oppskrift: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isImportReview ? 'Gjennomgå oppskrift' : 'Rediger oppskrift'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _onSave,
                child: Text(widget.isImportReview ? 'Lagre' : 'Oppdater'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 80,
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tittel',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tittel er påkrevd';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beskrivelse',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              if (widget.recipe.metadata?.sourceUrl != null &&
                  widget.recipe.metadata!.sourceUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kilde: ${widget.recipe.metadata!.sourceUrl}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _servingsController,
                      decoration: const InputDecoration(
                        labelText: 'Porsjoner',
                        border: OutlineInputBorder(),
                        helperText: 'Må være et heltall',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final servings = int.tryParse(value.trim());
                          if (servings == null || servings <= 0) {
                            return 'Må være et positivt heltall';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Bilde-URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tagger (kommaseparert)',
                  border: OutlineInputBorder(),
                  helperText: 'f.eks. Pizza, Deig, Italiensk',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ingredienser',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._editableIngredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                return _EditableIngredientWidget(
                  ingredient: ingredient,
                  onChanged: (updated) {
                    setState(() {
                      _editableIngredients[index] = updated;
                      _hasUnsavedChanges = true;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      _editableIngredients.removeAt(index);
                      _hasUnsavedChanges = true;
                    });
                  },
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _editableIngredients.add(_EditableIngredient(
                      amount: '',
                      unit: '',
                      item: '',
                      notes: '',
                    ));
                    _hasUnsavedChanges = true;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Legg til ingrediens'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Steg',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._editableSteps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return _EditableStepWidget(
                  step: step,
                  onChanged: (updated) {
                    setState(() {
                      _editableSteps[index] = updated;
                      _hasUnsavedChanges = true;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      _editableSteps.removeAt(index);
                      _hasUnsavedChanges = true;
                    });
                  },
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _editableSteps.add(_EditableStep(
                      stepNumber: _editableSteps.length + 1,
                      instruction: '',
                      notes: '',
                    ));
                    _hasUnsavedChanges = true;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Legg til steg'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _EditableIngredient {
  _EditableIngredient({
    required this.amount,
    required this.unit,
    required this.item,
    required this.notes,
  });

  String amount;
  String unit;
  String item;
  String notes;
}

class _EditableIngredientWidget extends StatelessWidget {
  const _EditableIngredientWidget({
    required this.ingredient,
    required this.onChanged,
    required this.onDelete,
  });

  final _EditableIngredient ingredient;
  final void Function(_EditableIngredient) onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: ingredient.amount,
                      decoration: const InputDecoration(
                      labelText: 'Mengde',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      onChanged(_EditableIngredient(
                        amount: value,
                        unit: ingredient.unit,
                        item: ingredient.item,
                        notes: ingredient.notes,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: ingredient.unit,
                      decoration: const InputDecoration(
                      labelText: 'Enhet',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      onChanged(_EditableIngredient(
                        amount: ingredient.amount,
                        unit: value,
                        item: ingredient.item,
                        notes: ingredient.notes,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: ingredient.item,
                      decoration: const InputDecoration(
                      labelText: 'Ingrediens',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      onChanged(_EditableIngredient(
                        amount: ingredient.amount,
                        unit: ingredient.unit,
                        item: value,
                        notes: ingredient.notes,
                      ));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Slett',
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: ingredient.notes,
              decoration: const InputDecoration(
                labelText: 'Notater (valgfritt)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
              onChanged: (value) {
                onChanged(_EditableIngredient(
                  amount: ingredient.amount,
                  unit: ingredient.unit,
                  item: ingredient.item,
                  notes: value,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableStep {
  _EditableStep({
    required this.stepNumber,
    required this.instruction,
    required this.notes,
  });

  final int stepNumber;
  String instruction;
  String notes;
}

class _EditableStepWidget extends StatelessWidget {
  const _EditableStepWidget({
    required this.step,
    required this.onChanged,
    required this.onDelete,
  });

  final _EditableStep step;
  final void Function(_EditableStep) onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Steg ${step.stepNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Slett',
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: step.instruction,
                    decoration: const InputDecoration(
                labelText: 'Instruksjon',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              onChanged: (value) {
                onChanged(_EditableStep(
                  stepNumber: step.stepNumber,
                  instruction: value,
                  notes: step.notes,
                ));
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: step.notes,
              decoration: const InputDecoration(
                labelText: 'Notater (valgfritt)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
              onChanged: (value) {
                onChanged(_EditableStep(
                  stepNumber: step.stepNumber,
                  instruction: step.instruction,
                  notes: value,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
