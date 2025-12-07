import 'package:flutter/material.dart';

import '../../../backend/quant_backend.dart';
import '../../../models/recipe.dart';
import '../../../screens/recipe_edit_screen.dart';
import '../models/pizza_calculator_config.dart';
import '../services/pizza_calculator_service.dart';

/// Screen for calculating pizza dough formulas.
class PizzaCalculatorScreen extends StatefulWidget {
  const PizzaCalculatorScreen({
    super.key,
    required this.variantId,
    required this.title,
    this.description,
  });

  final String variantId;
  final String title;
  final String? description;

  @override
  State<PizzaCalculatorScreen> createState() => _PizzaCalculatorScreenState();
}

class _PizzaCalculatorScreenState extends State<PizzaCalculatorScreen> {
  late PizzaCalculatorConfig _config;
  final PizzaCalculatorService _service = const PizzaCalculatorService();
  PizzaCalculatorResult? _result;

  @override
  void initState() {
    super.initState();
    _config = _getDefaultConfigForVariant(widget.variantId);
  }

  PizzaCalculatorConfig _getDefaultConfigForVariant(String variantId) {
    // Map variant IDs to presets
    if (variantId.contains('neapolitan')) {
      return PizzaCalculatorConfig.neapolitanDefaults();
    } else if (variantId.contains('ny') || variantId.contains('new-york')) {
      return PizzaCalculatorConfig.newYorkDefaults();
    } else if (variantId.contains('roman')) {
      return PizzaCalculatorConfig.romanDefaults();
    } else if (variantId.contains('detroit')) {
      return PizzaCalculatorConfig.detroitDefaults();
    } else if (variantId.contains('poolish')) {
      return PizzaCalculatorConfig.poolishDefaults();
    } else if (variantId.contains('cold-ferment')) {
      return PizzaCalculatorConfig.coldFermentDefaults();
    }
    return PizzaCalculatorConfig.genericDefaults();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.description != null) ...[
              Text(
                widget.description!,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
            ],
            _InputSection(
              config: _config,
              onConfigChanged: (newConfig) {
                setState(() {
                  _config = newConfig;
                  _result = null; // Clear result when inputs change
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onCalculate,
                child: const Text('Beregn'),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _ResultSection(
                result: _result!,
                config: _config,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onCalculate() {
    setState(() {
      _result = _service.calculate(_config);
    });
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.config,
    required this.onConfigChanged,
  });

  final PizzaCalculatorConfig config;
  final ValueChanged<PizzaCalculatorConfig> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inndata',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _NumberInput(
          label: 'Antall baller',
          value: config.ballCount.toDouble(),
          onChanged: (value) {
            onConfigChanged(config.copyWith(ballCount: value.toInt()));
          },
        ),
        const SizedBox(height: 16),
        _NumberInput(
          label: 'Vekt per ball (g)',
          value: config.ballWeightGrams,
          onChanged: (value) {
            onConfigChanged(config.copyWith(ballWeightGrams: value));
          },
        ),
        const SizedBox(height: 16),
        _NumberInput(
          label: 'Hydrering (%)',
          value: config.hydrationPercent,
          onChanged: (value) {
            onConfigChanged(config.copyWith(hydrationPercent: value));
          },
        ),
        const SizedBox(height: 16),
        _NumberInput(
          label: 'Salt (% av mel)',
          value: config.saltPercentOfFlour,
          onChanged: (value) {
            onConfigChanged(config.copyWith(saltPercentOfFlour: value));
          },
        ),
        const SizedBox(height: 16),
        _NumberInput(
          label: 'Gjær (% av mel)',
          value: config.yeastPercentOfFlour,
          onChanged: (value) {
            onConfigChanged(config.copyWith(yeastPercentOfFlour: value));
          },
        ),
        const SizedBox(height: 16),
        _NumberInput(
          label: 'Olje (% av mel)',
          value: config.oilPercentOfFlour ?? 0.0,
          onChanged: (value) {
            onConfigChanged(config.copyWith(oilPercentOfFlour: value > 0 ? value : null));
          },
        ),
        const SizedBox(height: 16),
        _NumberInput(
          label: 'Kaldgjæring (timer)',
          value: config.coldFermentHours,
          onChanged: (value) {
            onConfigChanged(config.copyWith(coldFermentHours: value));
          },
        ),
        const SizedBox(height: 16),
        _NumberInput(
          label: 'Romtemperaturgjæring (timer)',
          value: config.roomTempFermentHours,
          onChanged: (value) {
            onConfigChanged(config.copyWith(roomTempFermentHours: value));
          },
        ),
      ],
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''));
    
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.result,
    required this.config,
  });

  final PizzaCalculatorResult result;
  final PizzaCalculatorConfig config;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultat',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResultRow('Total deigvekt', '${result.totalDoughWeight.toStringAsFixed(1)} g'),
              const SizedBox(height: 8),
              _ResultRow('Mel', '${result.flourGrams.toStringAsFixed(1)} g'),
              const SizedBox(height: 8),
              _ResultRow('Vann', '${result.waterGrams.toStringAsFixed(1)} g'),
              const SizedBox(height: 8),
              _ResultRow('Salt', '${result.saltGrams.toStringAsFixed(1)} g'),
              const SizedBox(height: 8),
              _ResultRow('Gjær', '${result.yeastGrams.toStringAsFixed(2)} g'),
              if (result.oilGrams != null) ...[
                const SizedBox(height: 8),
                _ResultRow('Olivenolje', '${result.oilGrams!.toStringAsFixed(1)} g'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _onSaveAsRecipe(context, result, config),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lagre som oppskrift'),
          ),
        ),
      ],
    );
  }

  static Future<void> _onSaveAsRecipe(
    BuildContext context,
    PizzaCalculatorResult result,
    PizzaCalculatorConfig config,
  ) async {
    try {
      final recipe = result.toRecipe(config);
      final savedRecipe = await quantBackend.saveRecipe(recipe);

      if (!context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeEditScreen(recipe: savedRecipe),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke lagre oppskrift: $e'),
        ),
      );
    }
  }

  Widget _ResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

extension PizzaResultToRecipe on PizzaCalculatorResult {
  Recipe toRecipe(PizzaCalculatorConfig config) {
    final totalDoughWeightGrams = flourGrams + waterGrams + saltGrams + yeastGrams + (oilGrams ?? 0);

    final ingredients = <Ingredient>[
      Ingredient(amount: flourGrams, unit: 'g', item: 'Flour'),
      Ingredient(amount: waterGrams, unit: 'g', item: 'Water'),
      Ingredient(amount: saltGrams, unit: 'g', item: 'Salt'),
      Ingredient(amount: yeastGrams, unit: 'g', item: 'Yeast'),
      if (oilGrams != null) Ingredient(amount: oilGrams!, unit: 'g', item: 'Olive oil'),
    ];

    final steps = <RecipeStep>[
      RecipeStep(
        step: 1,
        instruction: 'Mix flour and water until no dry flour remains. Let rest for 20-30 minutes (autolyse).',
      ),
      RecipeStep(
        step: 2,
        instruction: 'Add salt and mix until well incorporated.',
      ),
      RecipeStep(
        step: 3,
        instruction: 'Add yeast${config.oilPercentOfFlour != null ? ' and olive oil' : ''} and mix until smooth.',
      ),
      RecipeStep(
        step: 4,
        instruction: 'Knead for 8-10 minutes until smooth and elastic.',
      ),
      if (config.coldFermentHours > 0)
        RecipeStep(
          step: 5,
          instruction: 'Cold ferment in refrigerator for ${config.coldFermentHours.toStringAsFixed(0)} hours.',
        ),
      RecipeStep(
        step: config.coldFermentHours > 0 ? 6 : 5,
        instruction: 'Let rise at room temperature for ${config.roomTempFermentHours.toStringAsFixed(0)} hours.',
      ),
      RecipeStep(
        step: config.coldFermentHours > 0 ? 7 : 6,
        instruction: 'Divide into ${config.ballCount} balls and shape.',
      ),
      RecipeStep(
        step: config.coldFermentHours > 0 ? 8 : 7,
        instruction: 'Final proof for 1-2 hours before baking.',
      ),
    ];

    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Pizza Dough – ${config.ballCount} × ${config.ballWeightGrams.toStringAsFixed(0)}g balls',
      description:
          'Generated from pizza calculator: '
          '${config.hydrationPercent.toStringAsFixed(1)}% hydration, '
          '${config.coldFermentHours.toStringAsFixed(0)}h cold + '
          '${config.roomTempFermentHours.toStringAsFixed(0)}h room temp fermentation. '
          'Total dough: ${totalDoughWeightGrams.toStringAsFixed(0)}g.',
      ingredients: ingredients,
      steps: steps,
      metadata: RecipeMetadata(
        categories: [
          'Pizza',
          'Dough',
          'Calculator Result',
          '${config.hydrationPercent.toStringAsFixed(0)}% Hydration',
        ],
        calculatorId: 'pizza',
        importMethod: 'calculator',
      ),
    );
  }
}
