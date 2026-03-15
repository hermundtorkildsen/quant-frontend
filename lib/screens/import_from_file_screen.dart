import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../backend/quant_backend.dart';
import '../models/recipe.dart';
import 'recipe_edit_screen.dart';

class ImportFromFileScreen extends StatefulWidget {
  const ImportFromFileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ImportFromFileScreen> createState() => _ImportFromFileScreenState();
}

class _ImportFromFileScreenState extends State<ImportFromFileScreen> {
  bool _loading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;

    final Uint8List? bytes = file.bytes;
    final String? name = file.name;

    if (bytes == null || name == null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final Recipe recipe =
      await quantBackend.importRecipeFromFile(bytes, name);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeEditScreen(recipe: recipe),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import feilet: $e'),
        ),
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

    if (widget.embedded) {
      return Center(
        child: _loading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: _pickFile,
          child: const Text('Velg fil'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Importer fra fil'),
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
                    Icons.upload_file_outlined,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Importer oppskrift fra fil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Velg en fil med en oppskrift for å importere den.',
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
                          'Formatet på filer kan variere.',
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
                      onPressed: _pickFile,
                      child: const Text('Velg fil'),
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