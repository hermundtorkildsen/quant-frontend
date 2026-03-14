import '../models/calculator_category.dart';
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
        title: 'Neapolitansk',
        description: 'Klassisk neapolitansk stil',
      ),
      CalculatorVariant(
        id: 'pizza-ny',
        title: 'New York',
        description: 'New York-stil pizzadeig',
      ),
      CalculatorVariant(
        id: 'pizza-roman',
        title: 'Romersk',
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
        title: 'Kaldgjæring',
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
    title: 'Generelle verktøy',
    icon: '🔧',
    description: 'Generelle kalkulatorer for matlaging',
    variants: [
      CalculatorVariant(
        id: 'general-units',
        title: 'Enheter',
        description: 'Konverter temperatur, volum og vekt',
      ),
    ],
  ),
];

