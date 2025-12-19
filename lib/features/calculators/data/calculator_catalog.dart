import '../models/calculator_category.dart';
import '../models/calculator_definition.dart';
import '../models/calculator_variant.dart';

/// List of all calculator categories available in the app.
final List<CalculatorCategory> calculatorCategories = [
  CalculatorCategory(
    id: 'pizza',
    title: 'Pizza',
    icon: '🍕',
    description: 'Deigformler for ulike pizzastiler',
    variants: [
      CalculatorVariant(
        id: 'pizza-neapolitan',
        title: 'Neapolitan',
        description: 'Klassisk neapolitansk stil',
      ),
      CalculatorVariant(
        id: 'pizza-ny',
        title: 'New York',
        description: 'New York-stil pizzadeig',
      ),
      CalculatorVariant(
        id: 'pizza-roman',
        title: 'Roman',
        description: 'Romersk stil pizza',
      ),
      CalculatorVariant(
        id: 'pizza-detroit',
        title: 'Detroit',
        description: 'Detroit-stil panne pizza',
      ),
      CalculatorVariant(
        id: 'pizza-poolish',
        title: 'Poolish',
        description: 'Poolish forgjæringsmetode',
      ),
      CalculatorVariant(
        id: 'pizza-cold-ferment',
        title: 'Cold Ferment',
        description: 'Lang kaldgjæring',
      ),
    ],
  ),
  CalculatorCategory(
    id: 'bread',
    title: 'Brød',
    icon: '🍞',
    description: 'Bakers prosent og brødoppskrifter',
    variants: [
      CalculatorVariant(
        id: 'bread-bakers-percent',
        title: 'Bakers prosent',
        description: 'Beregn ingrediensforhold',
      ),
    ],
  ),
  CalculatorCategory(
    id: 'general-tools',
    title: 'General Tools',
    icon: '🔧',
    description: 'Generelle kalkulatorer for matlaging',
    variants: [
      CalculatorVariant(
        id: 'general-temperature',
        title: 'Temperature Converter',
        description: 'Konverter mellom Celsius, Fahrenheit og Kelvin',
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
        description: 'Konverter mellom Celsius, Fahrenheit og Kelvin',
        fields: [
          CalculatorFieldDefinition(
            id: 'celsius',
            label: 'Celsius',
            type: CalculatorFieldType.number,
            unit: '°C',
            helpText: 'Skriv inn temperatur i Celsius',
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
            helpText: 'Skriv inn temperatur i Fahrenheit',
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
            helpText: 'Skriv inn temperatur i Kelvin',
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
          return 'Skriv inn en temperatur i et felt for å se konverteringer.';
        },
      );
    default:
      return null;
  }
}
