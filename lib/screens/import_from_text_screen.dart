import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backend/quant_backend.dart';
import 'recipe_edit_screen.dart';

/// Screen for importing a recipe from raw text.
class ImportFromTextScreen extends StatefulWidget {
  const ImportFromTextScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<ImportFromTextScreen> createState() => _ImportFromTextScreenState();
}

class _ImportFromTextScreenState extends State<ImportFromTextScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _sourceUrlController = TextEditingController();
  bool _isImporting = false;

  static const Color _backgroundColor = Color(0xfff7f4ef);
  static const Color _textColor = Color(0xff1f140f);

  @override
  void dispose() {
    _textController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }

  Widget _buildBody(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header section in card
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: _textColor.withOpacity(0.15),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lim inn en oppskrift fra en blogg, et dokument eller notater.',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vi forsøker å gjøre teksten om til en strukturert oppskrift som du kan redigere før du lagrer.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: _textColor.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(Icons.paste_outlined),
                          label: const Text('Lim inn fra utklippstavle'),
                        ),
                        TextButton.icon(
                          onPressed: _fillWithExample,
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Fyll med eksempel'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Text input card
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: _textColor.withOpacity(0.15),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          minLines: 8,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: 'Lim inn oppskrift her...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignLabelWithHint: true,
                          ),
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Source URL card (optional)
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: _textColor.withOpacity(0.15),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _sourceUrlController,
                          decoration: InputDecoration(
                            labelText: 'Kilde-URL (valgfritt)',
                            hintText: 'https://example.com/recipe',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Import button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isImporting ? null : _onImportPressed,
                        icon: _isImporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(_isImporting ? 'Importerer...' : 'Importer'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Importer fra tekst'),
      ),
      resizeToAvoidBottomInset: true,
      body: body,
    );
  }

  void _fillWithExample() {
    const exampleText = '''Sheperd's pie (rotete notater)

Stek kjøttdeig først, tror det var rundt 500 g. Litt salt + pepper. Hakk en stor gul løk og stek den sammen med kjøttdeigen til løken er myk.

Legg til en boks med hakkede tomater (ca 400 g) og la det småkoke i 10-15 minutter. Smak til med salt, pepper og kanskje litt timian.

Kok poteter (ca 1 kg) til de er møre. Mos dem med smør og litt melk. Jeg bruker gjerne rundt 50 g smør og 100 ml melk, men juster etter smak.

Legg kjøttblandingen i en ildfast form, og topp med potetmoset. Stek i ovnen på 200 grader i ca 30 minutter til toppen er gyllen.

Server med grønnsaker eller salat.''';

    _textController.text = exampleText;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksempeloppskrift fylt inn.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.trim().isNotEmpty) {
        _textController.text = data.text!;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tekst limt inn fra utklippstavle'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingen tekst i utklippstavlen'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke hente tekst fra utklippstavle'),
        ),
      );
    }
  }

  Future<void> _onImportPressed() async {
    final rawText = _textController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lim inn en oppskrift først.'),
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final sourceUrl = _sourceUrlController.text.trim();
      final recipe = await quantBackend.importRecipeFromText(
        rawText,
        sourceUrl: sourceUrl.isEmpty ? null : sourceUrl,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeEditScreen(recipe: recipe),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke importere oppskriften. Prøv igjen.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
}

