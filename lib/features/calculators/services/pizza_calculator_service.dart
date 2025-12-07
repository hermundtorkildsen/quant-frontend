import '../models/pizza_calculator_config.dart';

/// Result model for pizza dough calculator output.
class PizzaCalculatorResult {
  const PizzaCalculatorResult({
    required this.totalDoughWeight,
    required this.flourGrams,
    required this.waterGrams,
    required this.saltGrams,
    required this.yeastGrams,
    this.oilGrams,
  });

  final double totalDoughWeight;
  final double flourGrams;
  final double waterGrams;
  final double saltGrams;
  final double yeastGrams;
  final double? oilGrams;
}

/// Service for calculating pizza dough formulas from configuration.
///
/// TODO: Refine formulas for more accurate results.
/// Current implementation uses simple baker's percentage math.
class PizzaCalculatorService {
  const PizzaCalculatorService();

  /// Calculate dough ingredients from configuration.
  ///
  /// TODO: This is a placeholder implementation using basic baker's percentage.
  /// Future improvements:
  /// - Account for preferment hydration in poolish calculations
  /// - Adjust yeast based on fermentation time and temperature
  /// - Handle oil absorption in hydration calculations
  /// - More accurate weight loss during fermentation
  PizzaCalculatorResult calculate(PizzaCalculatorConfig config) {
    // Total dough weight = number of balls × weight per ball
    final totalDoughWeight = config.ballCount * config.ballWeightGrams;

    // Calculate flour using baker's percentage
    // Total dough = flour + water + salt + yeast + oil
    // If we have hydration%, salt%, yeast%, and optional oil%:
    // total = flour × (1 + hydration% + salt% + yeast% + oil%)
    final oilPercent = config.oilPercentOfFlour ?? 0.0;
    final totalPercent = 1.0 +
        (config.hydrationPercent / 100.0) +
        (config.saltPercentOfFlour / 100.0) +
        (config.yeastPercentOfFlour / 100.0) +
        (oilPercent / 100.0);

    final flourGrams = totalDoughWeight / totalPercent;
    final waterGrams = flourGrams * (config.hydrationPercent / 100.0);
    final saltGrams = flourGrams * (config.saltPercentOfFlour / 100.0);
    final yeastGrams = flourGrams * (config.yeastPercentOfFlour / 100.0);
    final oilGrams = oilPercent > 0 ? flourGrams * (oilPercent / 100.0) : null;

    return PizzaCalculatorResult(
      totalDoughWeight: totalDoughWeight,
      flourGrams: flourGrams,
      waterGrams: waterGrams,
      saltGrams: saltGrams,
      yeastGrams: yeastGrams,
      oilGrams: oilGrams,
    );
  }
}




