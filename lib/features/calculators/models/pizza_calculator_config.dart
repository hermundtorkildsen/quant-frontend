/// Configuration model for pizza dough calculator inputs.
class PizzaCalculatorConfig {
  const PizzaCalculatorConfig({
    required this.ballCount,
    required this.ballWeightGrams,
    required this.hydrationPercent,
    required this.saltPercentOfFlour,
    required this.yeastPercentOfFlour,
    this.oilPercentOfFlour,
    required this.coldFermentHours,
    required this.roomTempFermentHours,
  });

  final int ballCount;
  final double ballWeightGrams;
  final double hydrationPercent; // e.g. 60–75
  final double saltPercentOfFlour; // e.g. 2.5
  final double yeastPercentOfFlour; // e.g. 0.1–1.0 for baker's %
  final double? oilPercentOfFlour; // for NY style, optional
  final double coldFermentHours; // for fridge ferment
  final double roomTempFermentHours; // for room temp

  PizzaCalculatorConfig copyWith({
    int? ballCount,
    double? ballWeightGrams,
    double? hydrationPercent,
    double? saltPercentOfFlour,
    double? yeastPercentOfFlour,
    double? oilPercentOfFlour,
    double? coldFermentHours,
    double? roomTempFermentHours,
  }) {
    return PizzaCalculatorConfig(
      ballCount: ballCount ?? this.ballCount,
      ballWeightGrams: ballWeightGrams ?? this.ballWeightGrams,
      hydrationPercent: hydrationPercent ?? this.hydrationPercent,
      saltPercentOfFlour: saltPercentOfFlour ?? this.saltPercentOfFlour,
      yeastPercentOfFlour: yeastPercentOfFlour ?? this.yeastPercentOfFlour,
      oilPercentOfFlour: oilPercentOfFlour ?? this.oilPercentOfFlour,
      coldFermentHours: coldFermentHours ?? this.coldFermentHours,
      roomTempFermentHours: roomTempFermentHours ?? this.roomTempFermentHours,
    );
  }

  /// Neapolitan style defaults: 60–65% hydration, 24–48h cold ferment.
  static PizzaCalculatorConfig neapolitanDefaults() {
    return const PizzaCalculatorConfig(
      ballCount: 4,
      ballWeightGrams: 250,
      hydrationPercent: 62,
      saltPercentOfFlour: 2.5,
      yeastPercentOfFlour: 0.1,
      coldFermentHours: 24,
      roomTempFermentHours: 2,
    );
  }

  /// New York style defaults: oil %, sugar %, classic NY style.
  static PizzaCalculatorConfig newYorkDefaults() {
    return const PizzaCalculatorConfig(
      ballCount: 4,
      ballWeightGrams: 280,
      hydrationPercent: 60,
      saltPercentOfFlour: 2.0,
      yeastPercentOfFlour: 0.5,
      oilPercentOfFlour: 3.0,
      coldFermentHours: 0,
      roomTempFermentHours: 18,
    );
  }

  /// Roman style defaults: high-hydration, long ferment.
  static PizzaCalculatorConfig romanDefaults() {
    return const PizzaCalculatorConfig(
      ballCount: 4,
      ballWeightGrams: 300,
      hydrationPercent: 75,
      saltPercentOfFlour: 2.5,
      yeastPercentOfFlour: 0.2,
      coldFermentHours: 0,
      roomTempFermentHours: 24,
    );
  }

  /// Detroit pan style defaults: pan size → dough mass.
  static PizzaCalculatorConfig detroitDefaults() {
    return const PizzaCalculatorConfig(
      ballCount: 1,
      ballWeightGrams: 600,
      hydrationPercent: 70,
      saltPercentOfFlour: 2.2,
      yeastPercentOfFlour: 0.4,
      oilPercentOfFlour: 2.0,
      coldFermentHours: 0,
      roomTempFermentHours: 12,
    );
  }

  /// Poolish pizza defaults: preferment ratio → final dough.
  static PizzaCalculatorConfig poolishDefaults() {
    return const PizzaCalculatorConfig(
      ballCount: 4,
      ballWeightGrams: 260,
      hydrationPercent: 65,
      saltPercentOfFlour: 2.5,
      yeastPercentOfFlour: 0.3,
      coldFermentHours: 0,
      roomTempFermentHours: 2,
    );
  }

  /// Cold ferment optimizer defaults: adjust yeast for 12–72h.
  static PizzaCalculatorConfig coldFermentDefaults() {
    return const PizzaCalculatorConfig(
      ballCount: 4,
      ballWeightGrams: 250,
      hydrationPercent: 63,
      saltPercentOfFlour: 2.5,
      yeastPercentOfFlour: 0.05,
      coldFermentHours: 48,
      roomTempFermentHours: 1,
    );
  }

  /// Generic default for unknown variants.
  static PizzaCalculatorConfig genericDefaults() {
    return const PizzaCalculatorConfig(
      ballCount: 4,
      ballWeightGrams: 250,
      hydrationPercent: 65,
      saltPercentOfFlour: 2.5,
      yeastPercentOfFlour: 0.3,
      coldFermentHours: 0,
      roomTempFermentHours: 2,
    );
  }
}




