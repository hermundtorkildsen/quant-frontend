import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../backend/quant_backend.dart';
import 'recipe_edit_screen.dart';

/// Screen for importing a recipe from a URL using WebView.
/// Extracts recipe data from JSON-LD structured data or falls back to page text.
class ImportFromUrlScreen extends StatefulWidget {
  const ImportFromUrlScreen({
    super.key,
    required this.initialUrl,
    this.embedded = false,
  });

  final String initialUrl;
  final bool embedded;

  @override
  State<ImportFromUrlScreen> createState() => _ImportFromUrlScreenState();
}

class _ImportFromUrlScreenState extends State<ImportFromUrlScreen> {
  late final WebViewController _controller;
  late final TextEditingController _urlController;
  bool _isLoading = true;
  bool _isExtracting = false;
  bool _hasExtracted = false;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _urlController = TextEditingController(text: widget.initialUrl);
    _initializeWebView();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _currentUrl = url;
              _isLoading = false;
              _isExtracting = true;
            });
            // Update URL controller to show current URL
            if (widget.embedded && _urlController.text != url) {
              _urlController.text = url;
            }
            if (!_hasExtracted) {
              _extractRecipeData();
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _isExtracting = false;
              _hasExtracted = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  bool _looksLikeCookieConsentText(String text) {
    if (text.isEmpty) return false;
    
    final lowerText = text.toLowerCase();
    
    // Check for common consent/banner keywords
    final consentKeywords = [
      'cookie',
      'cookies',
      'samtykke',
      'consent',
      'privacy',
      'personvern',
      'detaljer',
      'avslå alle',
      'godta alle',
      'lagre valgte',
      'partners',
      'legitimate interest',
      'iab',
      'tcf',
    ];
    
    for (final keyword in consentKeywords) {
      if (lowerText.contains(keyword)) {
        return true;
      }
    }
    
    return false;
  }

  void _loadUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vennligst skriv inn en URL'),
        ),
      );
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL må starte med http:// eller https://'),
        ),
      );
      return;
    }

    setState(() {
      _hasExtracted = false;
      _isLoading = true;
      _isExtracting = false;
      _currentUrl = url;
    });

    _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _extractRecipeData() async {
    if (_hasExtracted) return;
    _hasExtracted = true;

    try {
      final jsCode = '''
        (function() {
          try {
            // Find all JSON-LD script tags
            const scripts = document.querySelectorAll('script[type="application/ld+json"]');
            let recipeData = null;

            // Try to find Recipe in JSON-LD
            for (let script of scripts) {
              try {
                let jsonData = JSON.parse(script.textContent);
                
                // Handle different JSON-LD formats
                let candidates = [];
                
                if (Array.isArray(jsonData)) {
                  candidates = jsonData;
                } else if (jsonData['@graph'] && Array.isArray(jsonData['@graph'])) {
                  candidates = jsonData['@graph'];
                } else {
                  candidates = [jsonData];
                }

                // Find Recipe type
                for (let candidate of candidates) {
                  const type = candidate['@type'];
                  const isRecipe = type === 'Recipe' || 
                                  (Array.isArray(type) && type.includes('Recipe')) ||
                                  type === 'https://schema.org/Recipe' ||
                                  (Array.isArray(type) && type.some(t => 
                                    t === 'https://schema.org/Recipe' || 
                                    t === 'http://schema.org/Recipe'
                                  ));

                  if (isRecipe) {
                    recipeData = candidate;
                    break;
                  }
                }

                if (recipeData) break;
              } catch (e) {
                // Skip invalid JSON
                continue;
              }
            }

            if (recipeData) {
              // Extract recipe fields
              const title = recipeData.name || recipeData.headline || '';
              
              // Extract ingredients
              let ingredients = [];
              if (recipeData.recipeIngredient) {
                if (Array.isArray(recipeData.recipeIngredient)) {
                  ingredients = recipeData.recipeIngredient.map(ing => {
                    if (typeof ing === 'string') return ing;
                    if (ing.text) return ing.text;
                    return String(ing);
                  });
                } else if (typeof recipeData.recipeIngredient === 'string') {
                  ingredients = [recipeData.recipeIngredient];
                }
              }

              // Extract instructions
              let steps = [];
              if (recipeData.recipeInstructions) {
                if (typeof recipeData.recipeInstructions === 'string') {
                  steps = [recipeData.recipeInstructions];
                } else if (Array.isArray(recipeData.recipeInstructions)) {
                  steps = recipeData.recipeInstructions.map(step => {
                    if (typeof step === 'string') return step;
                    if (step.text) return step.text;
                    if (step['@type'] === 'HowToStep' && step.text) return step.text;
                    return String(step);
                  });
                }
              }

              return JSON.stringify({
                kind: 'recipe',
                title: title,
                ingredients: ingredients,
                steps: steps
              });
            } else {
              // Fallback: extract page text
              const bodyText = document.body ? document.body.innerText : '';
              return JSON.stringify({
                kind: 'text',
                text: bodyText
              });
            }
          } catch (e) {
            // Fallback on any error
            const bodyText = document.body ? document.body.innerText : '';
            return JSON.stringify({
              kind: 'text',
              text: bodyText
            });
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      
      setState(() {
        _isExtracting = false;
      });

      // Parse the result
      String jsonString;
      if (result is String) {
        // Remove quotes if JavaScript returned a quoted string
        jsonString = result;
        if (jsonString.isNotEmpty) {
          final firstChar = jsonString[0];
          final lastChar = jsonString[jsonString.length - 1];
          if ((firstChar == '"' || firstChar == "'") && firstChar == lastChar) {
            jsonString = jsonString.substring(1, jsonString.length - 1);
          }
        }
        // Unescape JSON string if needed
        jsonString = jsonString.replaceAll('\\"', '"').replaceAll('\\n', '\n');
      } else {
        jsonString = result.toString();
      }

      // Try to decode JSON and import
      try {
        final decoded = jsonDecode(jsonString);
        debugPrint('=== Extracted Recipe Data ===');
        debugPrint(jsonEncode(decoded));
        debugPrint('===========================');

        // Import the extracted data
        String textToImport;
        String? extractedKind;
        if (decoded is Map<String, dynamic>) {
          extractedKind = decoded['kind'] as String?;
          if (decoded['kind'] == 'recipe') {
            // Format structured recipe as text
            final buffer = StringBuffer();
            if (decoded['title'] != null) {
              buffer.writeln(decoded['title']);
              buffer.writeln();
            }
            if (decoded['ingredients'] != null && decoded['ingredients'] is List) {
              buffer.writeln('Ingredienser:');
              for (final ing in decoded['ingredients']) {
                buffer.writeln('- $ing');
              }
              buffer.writeln();
            }
            if (decoded['steps'] != null && decoded['steps'] is List) {
              buffer.writeln('Instruksjoner:');
              for (int i = 0; i < decoded['steps'].length; i++) {
                buffer.writeln('${i + 1}. ${decoded['steps'][i]}');
              }
            }
            textToImport = buffer.toString();
          } else if (decoded['kind'] == 'text' && decoded['text'] != null) {
            var extractedText = decoded['text'] as String;
            
            // Normalize line endings
            extractedText = extractedText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
            
            // Check for cookie consent banner
            if (_looksLikeCookieConsentText(extractedText) && extractedText.length < 2000) {
              // Likely a cookie consent banner - don't import
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _isExtracting = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This page is showing a cookie consent dialog. Please accept/decline cookies on the page, then tap Load again.',
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
              return;
            }
            
            // Hard-cap length at 25000 characters
            const maxLength = 25000;
            if (extractedText.length > maxLength) {
              extractedText = extractedText.substring(0, maxLength);
            }
            
            textToImport = extractedText;
          } else {
            textToImport = jsonEncode(decoded);
          }
        } else {
          textToImport = jsonString;
        }

        // Call backend to import
        if (!mounted) return;
        
        // Debug logging: inspect what is being sent to backend
        if (kDebugMode) {
          final sourceUrl = _currentUrl.isNotEmpty ? _currentUrl : null;
          final textLength = textToImport.length;
          final textHead = textLength > 0 
              ? textToImport.substring(0, textLength > 600 ? 600 : textLength)
              : '';
          final textTail = textLength > 600
              ? textToImport.substring(textLength - 600)
              : textToImport;
          
          print('=== URL_IMPORT_PAYLOAD ===');
          print('url=$sourceUrl');
          print('kind=$extractedKind');
          print('len=$textLength');
          print('HEAD_START');
          print(textHead);
          print('HEAD_END');
          print('TAIL_START');
          print(textTail);
          print('TAIL_END');
          
          // Simple debug log: kind and payload length
          print('URL_IMPORT: kind=$extractedKind, payload_length=$textLength');
        }
        
        final recipe = await quantBackend.importRecipeFromText(
          textToImport,
          sourceUrl: _currentUrl.isNotEmpty ? _currentUrl : null,
        );

        if (!mounted) return;

        // Navigate to edit screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeEditScreen(recipe: recipe),
          ),
        );
      } catch (e) {
        debugPrint('Failed to decode or import extracted data: $e');
        debugPrint('Raw result: $jsonString');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kunne ikke importere oppskriften. Prøv igjen.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error extracting recipe data: $e');
      setState(() {
        _isExtracting = false;
      });
    }
  }

  Widget _buildUrlInput() {
    if (!widget.embedded) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/recipe',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _loadUrl(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _loadUrl,
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Load'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildUrlInput(),
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading || _isExtracting)
                Container(
                  color: Colors.white.withOpacity(0.9),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _isLoading ? 'Loading page…' : 'Extracting recipe…',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import recipe'),
      ),
      body: body,
    );
  }
}

