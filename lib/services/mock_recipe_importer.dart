import '../models/recipe.dart';

/// Mock implementation that simulates an AI service parsing free text into
/// a structured Recipe JSON, then converts it to a Recipe model.
Future<Recipe> mockImportFromText(
  String rawText, {
  String? sourceUrl,
}) async {
  // Simulate some network / processing latency.
  await Future.delayed(const Duration(milliseconds: 600));

  final lines = rawText
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final title = lines.isNotEmpty ? lines.first : 'Imported recipe';
  final description = lines.length > 1 ? lines.sublist(1).join(' ') : null;

  final json = <String, dynamic>{
    'id': 'imported-${DateTime.now().millisecondsSinceEpoch}',
    'title': title,
    'description': description,
    'servings': 2,
    'ingredients': [
      {
        'amount': 500,
        'unit': 'g',
        'item': 'example ingredient 1',
        'notes': 'Mocked by AI from import text',
      },
      {
        'amount': 10,
        'unit': 'g',
        'item': 'example ingredient 2',
        'notes': null,
      },
    ],
    'steps': [
      {
        'step': 1,
        'instruction': 'Review this imported recipe and adjust as needed.',
        'notes': '',
      },
      {
        'step': 2,
        'instruction': 'Replace mock ingredients with real ones later.',
        'notes': '',
      },
    ],
    'metadata': {
      'source_url': sourceUrl ?? '',
      'author': 'Mock AI',
      'language': 'en',
      'categories': <String>[],
      'image_url': null,
      'calculator_id': null,
      'import_method': 'text',
    },
  };

  return Recipe.fromJson(json);
}
