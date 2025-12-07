/// Field types supported by the generic calculator framework.
enum CalculatorFieldType {
  number,
  dropdown,
  slider,
}

/// Definition of a single input field in a calculator.
class CalculatorFieldDefinition {
  const CalculatorFieldDefinition({
    required this.id,
    required this.label,
    required this.type,
    this.helpText,
    this.unit,
    this.defaultValue,
    this.options,
    this.min,
    this.max,
    this.step,
    this.onFieldChanged,
  });

  /// Unique identifier for this field.
  final String id;

  /// Human-readable label.
  final String label;

  /// Type of input field.
  final CalculatorFieldType type;

  /// Optional help text shown below the field.
  final String? helpText;

  /// Optional unit label (e.g., "g", "ml", "°C").
  final String? unit;

  /// Default value (string for dropdown, number for number/slider).
  final dynamic defaultValue;

  /// Options for dropdown fields.
  final List<String>? options;

  /// Minimum value for number/slider fields.
  final double? min;

  /// Maximum value for number/slider fields.
  final double? max;

  /// Step value for slider fields.
  final double? step;

  /// Optional callback when field value changes.
  /// Parameters: (changedFieldId, newValue, allFieldValues)
  final void Function(String fieldId, dynamic newValue, Map<String, dynamic> allValues)? onFieldChanged;
}

/// Complete definition of a calculator that can be rendered generically.
class CalculatorDefinition {
  const CalculatorDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.fields,
    this.calculate,
  });

  /// Unique identifier for this calculator.
  final String id;

  /// Display title.
  final String title;

  /// Description/help text.
  final String description;

  /// List of input fields.
  final List<CalculatorFieldDefinition> fields;

  /// Optional calculation function. If provided, called when user taps Calculate.
  /// Takes field values, returns formatted result string.
  /// If null, screen will echo inputs (backward compatible).
  final String Function(Map<String, dynamic> fieldValues)? calculate;
}

