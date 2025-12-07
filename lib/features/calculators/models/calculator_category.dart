import 'calculator_variant.dart';

/// A category of calculators (e.g. Pizza, Sourdough, Fermentation).
class CalculatorCategory {
  const CalculatorCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.variants,
  });

  final String id;
  final String title;
  final String icon; // emoji string like "🍕"
  final String description;
  final List<CalculatorVariant> variants;
}




