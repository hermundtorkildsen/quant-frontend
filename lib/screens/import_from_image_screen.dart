import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../backend/quant_backend.dart';
import '../models/recipe.dart';
import 'recipe_edit_screen.dart';

class ImportFromImageScreen extends StatefulWidget {
  const ImportFromImageScreen({super.key});

  @override
  State<ImportFromImageScreen> createState() => _ImportFromImageScreenState();
}

class _ImportFromImageScreenState extends State<ImportFromImageScreen> {
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 70,
    );

    if (picked == null) return;

    final file = File(picked.path);

    setState(() {
      _loading = true;
    });

    try {
      final recipe = await quantBackend.importRecipeFromImage(file);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeEditScreen(recipe: recipe),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import feilet: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Importer fra bilde'),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height
                  - kToolbarHeight
                  - MediaQuery.of(context).padding.top
                  - 48,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 64,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Importer oppskrift fra bilde',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Velg et bilde av en oppskrift for å importere den.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(height: 12),
                        Text(
                          'For best resultat bør bildet være tydelig og lett å lese, spesielt ved håndskrift.',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Kontroller ingredienser og fremgangsmåte før du lagrer.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Velg bilde'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}