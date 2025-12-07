import 'package:flutter/material.dart';

import '../data/calculator_catalog.dart';
import '../models/calculator_category.dart';
import '../models/calculator_definition.dart';
import '../models/calculator_variant.dart';
import 'bakers_percentage_screen.dart';
import 'generic_calculator_screen.dart';
import 'pizza_calculator_screen.dart';
import 'temperature_converter_screen.dart';

/// Screen showing all variants within a calculator category.
class CalculatorCategoryScreen extends StatelessWidget {
  const CalculatorCategoryScreen({super.key, required this.category});

  final CalculatorCategory category;

  static const Color _backgroundColor = Color(0xfff7f4ef);
  static const Color _textColor = Color(0xff1f140f);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(category.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(category: category),
            const SizedBox(height: 32),
            ...category.variants.map(
              (variant) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VariantCard(
                  variant: variant,
                  categoryId: category.id,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.category});

  final CalculatorCategory category;

  static const Color _textColor = Color(0xff1f140f);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.icon,
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 16),
        Text(
          category.title,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          category.description,
          style: textTheme.bodyLarge?.copyWith(
            color: _textColor.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.variant,
    required this.categoryId,
  });

  final CalculatorVariant variant;
  final String categoryId;

  static const Color _textColor = Color(0xff1f140f);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: _textColor.withOpacity(0.15),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // Navigate to pizza calculator for pizza category variants
          if (categoryId == 'pizza') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PizzaCalculatorScreen(
                  variantId: variant.id,
                  title: variant.title,
                  description: variant.description,
                ),
              ),
            );
          } else if (categoryId == 'bread' &&
              variant.id == 'bread-bakers-percent') {
            // Navigate to baker's percentage calculator
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BakersPercentageScreen(
                  title: variant.title,
                  description: variant.description,
                ),
              ),
            );
          } else if (categoryId == 'general-tools' &&
              variant.id == 'general-temperature') {
            // Navigate to generic calculator screen for temperature converter
            final definition = getCalculatorDefinitionForVariant(variant.id);
            if (definition != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GenericCalculatorScreen(
                    definition: definition,
                  ),
                ),
              );
            } else {
              // Fallback to old screen if definition not found
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TemperatureConverterScreen(
                    title: variant.title,
                    description: variant.description,
                  ),
                ),
              );
            }
          } else {
            // For other categories, show "not implemented" message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${variant.title} kalkulator kommer snart!'),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      variant.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: _textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _textColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
