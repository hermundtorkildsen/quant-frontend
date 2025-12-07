import '../models/calculator_category.dart';
import '../models/calculator_definition.dart';
import '../models/calculator_variant.dart';

/// List of all calculator categories available in the app.
final List<CalculatorCategory> calculatorCategories = [
  CalculatorCategory(
    id: 'pizza',
    title: 'Pizza',
    icon: '🍕',
    description: 'Dough formulas for different pizza styles',
    variants: [
      CalculatorVariant(
        id: 'pizza-neapolitan',
        title: 'Neapolitan',
        description: 'Classic Neapolitan style',
      ),
      CalculatorVariant(
        id: 'pizza-ny',
        title: 'New York',
        description: 'NY style pizza dough',
      ),
      CalculatorVariant(
        id: 'pizza-roman',
        title: 'Roman',
        description: 'Roman style pizza',
      ),
      CalculatorVariant(
        id: 'pizza-detroit',
        title: 'Detroit',
        description: 'Detroit style pan pizza',
      ),
      CalculatorVariant(
        id: 'pizza-poolish',
        title: 'Poolish',
        description: 'Poolish preferment method',
      ),
      CalculatorVariant(
        id: 'pizza-cold-ferment',
        title: 'Cold Ferment',
        description: 'Long cold fermentation',
      ),
    ],
  ),
  CalculatorCategory(
    id: 'bread',
    title: 'Bread',
    icon: '🍞',
    description: 'Baker\'s percentage and bread formulas',
    variants: [
      CalculatorVariant(
        id: 'bread-bakers-percent',
        title: 'Baker\'s Percentage',
        description: 'Calculate ingredient ratios',
      ),
    ],
  ),
  CalculatorCategory(
    id: 'general-tools',
    title: 'General Tools',
    icon: '🔧',
    description: 'General purpose cooking calculators',
    variants: [
      CalculatorVariant(
        id: 'general-temperature',
        title: 'Temperature Converter',
        description: 'Convert between Celsius, Fahrenheit, and Kelvin',
      ),
    ],
  ),
];

/// Get the calculator definition for a specific variant ID.
/// Returns null if no definition exists for the variant.
CalculatorDefinition? getCalculatorDefinitionForVariant(String variantId) {
  switch (variantId) {
    case 'general-temperature':
      return CalculatorDefinition(
        id: 'general-temperature',
        title: 'Temperature Converter',
        description: 'Convert between Celsius, Fahrenheit, and Kelvin',
        fields: [
          CalculatorFieldDefinition(
            id: 'celsius',
            label: 'Celsius',
            type: CalculatorFieldType.number,
            unit: '°C',
            helpText: 'Enter temperature in Celsius',
            onFieldChanged: (changedFieldId, newValue, allValues) {
              // When Celsius changes, update Fahrenheit and Kelvin
              if (changedFieldId == 'celsius') {
                final celsius = double.tryParse(newValue.toString());
                if (celsius != null) {
                  allValues['fahrenheit'] = (celsius * 9 / 5) + 32;
                  allValues['kelvin'] = celsius + 273.15;
                } else if (newValue.toString().isEmpty) {
                  allValues.remove('fahrenheit');
                  allValues.remove('kelvin');
                }
              }
            },
          ),
          CalculatorFieldDefinition(
            id: 'fahrenheit',
            label: 'Fahrenheit',
            type: CalculatorFieldType.number,
            unit: '°F',
            helpText: 'Enter temperature in Fahrenheit',
            onFieldChanged: (changedFieldId, newValue, allValues) {
              // When Fahrenheit changes, update Celsius and Kelvin
              if (changedFieldId == 'fahrenheit') {
                final fahrenheit = double.tryParse(newValue.toString());
                if (fahrenheit != null) {
                  final celsius = (fahrenheit - 32) * 5 / 9;
                  allValues['celsius'] = celsius;
                  allValues['kelvin'] = celsius + 273.15;
                } else if (newValue.toString().isEmpty) {
                  allValues.remove('celsius');
                  allValues.remove('kelvin');
                }
              }
            },
          ),
          CalculatorFieldDefinition(
            id: 'kelvin',
            label: 'Kelvin',
            type: CalculatorFieldType.number,
            unit: 'K',
            helpText: 'Enter temperature in Kelvin',
            onFieldChanged: (changedFieldId, newValue, allValues) {
              // When Kelvin changes, update Celsius and Fahrenheit
              if (changedFieldId == 'kelvin') {
                final kelvin = double.tryParse(newValue.toString());
                if (kelvin != null) {
                  final celsius = kelvin - 273.15;
                  allValues['celsius'] = celsius;
                  allValues['fahrenheit'] = (celsius * 9 / 5) + 32;
                } else if (newValue.toString().isEmpty) {
                  allValues.remove('celsius');
                  allValues.remove('fahrenheit');
                }
              }
            },
          ),
        ],
        calculate: (values) {
          // Not needed for live conversion, but kept for backward compatibility
          return 'Enter a temperature in any field to see conversions.';
        },
      );
    default:
      return null;
  }
}
