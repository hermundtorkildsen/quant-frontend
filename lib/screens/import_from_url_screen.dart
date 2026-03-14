import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../auth/auth_expired_handler.dart';
import '../backend/quant_backend.dart';
import '../screens/recipe_edit_screen.dart';

/// Screen for importing a recipe from a URL using WebView.
/// Extracts recipe data from JSON-LD structured data, then DOM heuristics,
/// then falls back to cleaned page text.
///
/// Goal: maximize success rate across many recipe sites.
/// Limits: paywalls/login-only pages cannot be bypassed.
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

  bool _isLoading = false;
  bool _isExtracting = false;
  bool _isImporting = false;

  String _currentUrl = '';

  int _attempt = 0;
  bool _importTriggered = false;
  DateTime? _extractStart;

  static const int _maxTextLength = 25000;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _urlController = TextEditingController(text: widget.initialUrl);

    _initializeWebView();

    if (widget.initialUrl.isNotEmpty) {
      _controller.loadRequest(Uri.parse(widget.initialUrl));
      setState(() => _isLoading = true);
    }
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
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _isExtracting = false;
              _isImporting = false;
              _currentUrl = url;
            });
            _attempt = 0;
            _importTriggered = false;
            _extractStart = null;
          },
          onPageFinished: (String url) {
            setState(() {
              _currentUrl = url;
              _isLoading = false;
              _isExtracting = true;
            });

            if (widget.embedded && _urlController.text != url) {
              _urlController.text = url;
            }

            _scheduleExtract();
          },
        ),
      );
  }

  void _loadUrl() {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vennligst skriv inn en URL')),
      );
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL må starte med http:// eller https://')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isExtracting = false;
      _isImporting = false;
      _currentUrl = url;
    });

    _attempt = 0;
    _importTriggered = false;

    _controller.loadRequest(Uri.parse(url));
    setState(() => _isExtracting = true);
    _extractStart = null;
    _scheduleExtract();
  }

  void _scheduleExtract() {
    if (_importTriggered) return;

    _extractStart ??= DateTime.now();

    final elapsed = DateTime.now().difference(_extractStart!);

    // Stop after 20 seconds
    if (elapsed > const Duration(seconds: 20)) {
      if (!mounted) return;

      setState(() => _isExtracting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kunne ikke hente oppskrift fra denne nettsiden. '
                'Tips: Kopier teksten fra nettsiden og importer via "Importer fra tekst".',
          ),
          duration: Duration(seconds: 6),
        ),
      );

      return;
    }


    const pollDelay = Duration(milliseconds: 900);

    Future.delayed(pollDelay, () async {
      if (!mounted) return;
      if (_importTriggered) return;

      await _extractRecipeData();

      if (!_importTriggered) {
        _scheduleExtract();
      }
    });
  }


  Future<void> _extractRecipeData() async {
    if (_importTriggered) return;
    _attempt++;

    try {
      final result = await _controller.runJavaScriptReturningResult(_jsExtractRecipe(hard: _attempt >= 3));
      if (!mounted) return;

      final decoded = _decodeWebViewJson(result);

      String textToImport = '';
      String kind = 'unknown';
      String? pageUrl;

      if (decoded is Map<String, dynamic>) {
        kind = (decoded['kind'] ?? 'unknown').toString();
        pageUrl = decoded['sourceUrl']?.toString();

        if (kind == 'recipe') {
          textToImport = _formatRecipeForClaude(decoded);
        } else if (kind == 'text') {
          final raw = (decoded['text'] ?? '').toString();
          textToImport = _cleanAndCapText(raw);
        } else {
          textToImport = _cleanAndCapText(jsonEncode(decoded));
        }
      } else {
        textToImport = _cleanAndCapText(decoded?.toString() ?? '');
      }

      final sourceUrl = (pageUrl != null && pageUrl.trim().isNotEmpty) ? pageUrl.trim() : _currentUrl;

      if (sourceUrl.isEmpty) return;

      // Heuristics: detect consent/paywall/empty so we can retry and not import junk
      if (_looksBlockedOrEmpty(textToImport)) {
        // If cookie/consent-like, show hint but allow retries
        if (_looksLikeCookieConsentText(textToImport)) {
          if (_attempt == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hvis siden viser cookie-dialog: godta/avslå i webview og vent litt.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
        return; // let retries happen
      }

      // If we got meaningful content, trigger import once.
      _importTriggered = true;

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isExtracting = false;
          _isImporting = true;
        });
      }

      if (kDebugMode) {
        final len = textToImport.length;
        final head = len > 0 ? textToImport.substring(0, len > 600 ? 600 : len) : '';
        final tail = len > 600 ? textToImport.substring(len - 600) : textToImport;

        debugPrint('=== URL_IMPORT_PAYLOAD ===');
        debugPrint('url=$sourceUrl');
        debugPrint('kind=$kind');
        debugPrint('len=$len');
        debugPrint('HEAD_START\n$head\nHEAD_END');
        debugPrint('TAIL_START\n$tail\nTAIL_END');
      }

      final recipe = await quantBackend.importRecipeFromText(
        textToImport,
        sourceUrl: sourceUrl,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RecipeEditScreen(recipe: recipe)),
      );

      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _isExtracting = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final handled = await maybeHandleAuthExpired(context, e);
      if (handled) return;

      // Keep extracting state off on hard failure.
      setState(() {
        _isExtracting = false;
        _isImporting = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke hente/importere oppskriften. Prøv igjen.')),
      );
    }
  }

  // ---------------------------
  //  Parsing / formatting helpers
  // ---------------------------

  dynamic _decodeWebViewJson(Object? result) {
    if (result == null) return null;

    if (result is String) {
      final s = result.trim();

      // Sometimes it returns JSON directly
      if (s.startsWith('{') || s.startsWith('[')) {
        return jsonDecode(s);
      }

      // Sometimes it returns a quoted JSON-string
      final unquoted = jsonDecode(s);
      if (unquoted is String) {
        return jsonDecode(unquoted);
      }
      return unquoted;
    }

    // Fallback
    return jsonDecode(result.toString());
  }

  String _cleanAndCapText(String input) {
    var t = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Normaliser non-breaking spaces
    t = t.replaceAll('\u00A0', ' ');

    // Fjern trailing spaces før linjeskift
    t = t.replaceAll(RegExp(r'[ \t]+\n'), '\n');

    // Kollaps mange spaces/tab inni linjer
    t = t.replaceAll(RegExp(r'[ \t]{2,}'), ' ');

    // Maks 2–3 blanklinjer på rad
    t = t.replaceAll(RegExp(r'\n{4,}'), '\n\n\n');

    t = t.trim();

    if (t.length <= _maxTextLength) return t;

    final headLen = (_maxTextLength * 0.6).floor();
    final tailLen = _maxTextLength - headLen;

    final head = t.substring(0, headLen);
    final tail = t.substring(t.length - tailLen);

    return (head +
        '\n\n--- (tekst forkortet for import) ---\n\n' +
        tail).trim();
  }

  String _formatRecipeForClaude(Map<String, dynamic> decoded) {
    final title = (decoded['title'] ?? '').toString().trim();

    final ingredients = (decoded['ingredients'] is List)
        ? (decoded['ingredients'] as List).map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList()
        : <String>[];

    final steps = (decoded['steps'] is List)
        ? (decoded['steps'] as List).map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList()
        : <String>[];

    final b = StringBuffer();

    if (title.isNotEmpty) {
      b.writeln(title);
      b.writeln();
    }

    // Context first helps sectioning + Claude inference
    if (steps.isNotEmpty) {
      b.writeln('Oppskriftstekst:');
      for (final s in steps) {
        b.writeln(s);
      }
      b.writeln();
    }

    if (ingredients.isNotEmpty) {
      b.writeln('Ingredienser:');
      for (final ing in ingredients) {
        b.writeln('- ${ing.trim()}');
      }
      b.writeln();
    }

    if (steps.isNotEmpty) {
      b.writeln('Instruksjoner:');
      var i = 1;
      for (final s in steps) {
        final line = s.trim();
        if (line.endsWith(':')) {
          b.writeln(line);
        } else {
          b.writeln('${i++}. $line');
        }
      }
    }

    return _cleanAndCapText(b.toString());
  }

  bool _looksLikeCookieConsentText(String text) {
    if (text.isEmpty) return false;

    final lower = text.toLowerCase();

    const consentKeywords = [
      'cookie',
      'cookies',
      'samtykke',
      'consent',
      'privacy',
      'personvern',
      'avslå alle',
      'godta alle',
      'lagre valgte',
      'legitimate interest',
      'iab',
      'tcf',
      'cmp',
      'vendor',
    ];

    for (final k in consentKeywords) {
      if (lower.contains(k)) return true;
    }
    return false;
  }

  bool _looksBlockedOrEmpty(String text) {
    final t = text.trim();
    if (t.isEmpty) return true;

    // For streng før: 400 kan drepe korte oppskrifter (dressing/drink).
    if (t.length < 200) return true;

    final lower = t.toLowerCase();

    // åpenbar paywall/login
    const blockedHints = [
      'logg inn',
      'abonnement',
      'prøv gratis',
      'betal',
      'subscribe',
      'sign in',
      'login',
      'member',
      'premium',
    ];
    for (final h in blockedHints) {
      if (lower.contains(h)) return true;
    }

    // Hvis det ser ut som cookie-consent, la retry fortsette (ikke blokker hardt her)
    if (_looksLikeCookieConsentText(t)) {
      return true;
    }

    return false;
  }


  // ---------------------------
  //  JS extraction
  // ---------------------------


  String _jsExtractRecipe({required bool hard}) => '''
(function() {
  function normalizeText(s) {
    if (!s) return '';
    return String(s)
      .replace(/\\r\\n/g, '\\n')
      .replace(/\\r/g, '\\n')
      .replace(/[ \\t]+\\n/g, '\\n')
      .replace(/\\n{4,}/g, '\\n\\n\\n')
      .trim();
  }
  
  function safeText(s) {
    if (!s) return '';
    return normalizeText(String(s)).replace(/\s+/g, ' ').trim();
  }
  
    function flattenCandidates(jsonData) {
    if (!jsonData) return [];

    if (Array.isArray(jsonData)) return jsonData;

    if (jsonData['@graph'] && Array.isArray(jsonData['@graph'])) {
      return jsonData['@graph'];
    }

    if (jsonData.mainEntity) {
      if (Array.isArray(jsonData.mainEntity)) return jsonData.mainEntity;
      return [jsonData.mainEntity];
    }

    return [jsonData];
  }

  function isRecipeType(type) {
    if (!type) return false;

    if (type === 'Recipe') return true;
    if (type === 'https://schema.org/Recipe') return true;
    if (type === 'http://schema.org/Recipe') return true;

    if (Array.isArray(type)) {
      for (const t of type) {
        if (
          t === 'Recipe' ||
          t === 'https://schema.org/Recipe' ||
          t === 'http://schema.org/Recipe'
        ) {
          return true;
        }
      }
    }

    return false;
  }

  function getCleanVisibleText(isHard) {
    const root =
      document.querySelector('article') ||
      document.querySelector('main') ||
      document.querySelector('[role="main"]') ||
      document.body;

    if (!root) return '';

    const node = root.cloneNode(true);

    // Always remove obvious noise (generic, not site-specific)
    const baseSelectors = [
      'script','style','noscript',
      'nav','header','footer','aside',
      '[role="navigation"]',

      // common overlays / banners
      '[aria-modal="true"]',
      '[class*="cookie"]','[id*="cookie"]',
      '[class*="consent"]','[id*="consent"]',
      '[class*="banner"]','[id*="banner"]',
      '[class*="modal"]','[id*="modal"]',
      '[class*="subscribe"]','[id*="subscribe"]',
      '[class*="paywall"]','[id*="paywall"]',
    ];

    // Hard pass removes more "often-noise" areas if we keep failing
    const hardSelectors = [
      '[class*="comment"]','[id*="comment"]',
      '[class*="newsletter"]','[id*="newsletter"]',
      '[class*="signup"]','[id*="signup"]',
      '[class*="share"]','[id*="share"]',
      '[class*="social"]','[id*="social"]',
      '[class*="related"]','[id*="related"]',
      '[class*="recommend"]','[id*="recommend"]',
      'form',
    ];

    const selectors = isHard ? baseSelectors.concat(hardSelectors) : baseSelectors;

    for (const sel of selectors) {
      const els = node.querySelectorAll(sel);
      for (const el of els) el.remove();
    }

    return node.innerText || '';
  }

  try {
  
//      // -------------------------
//  // Try JSON-LD recipe first
//  // -------------------------
//
//  try {
//    const scripts = document.querySelectorAll('script[type="application/ld+json"]');
//
//    for (const script of scripts) {
//      try {
//        const raw = script.textContent;
//        if (!raw) continue;
//
//        const jsonData = JSON.parse(raw);
//        const candidates = flattenCandidates(jsonData);
//
//        for (const c of candidates) {
//          if (c && isRecipeType(c['@type'])) {
//
//            const title = safeText(c.name || c.headline || '');
//
//            let ingredients = [];
//
//            if (typeof c.recipeIngredient === 'string') {
//              const cleaned = safeText(c.recipeIngredient);
//              if (cleaned) {
//                ingredients = [cleaned];
//              }
//            } else if (Array.isArray(c.recipeIngredient)) {
//              ingredients = c.recipeIngredient
//                .map(x => {
//                  if (typeof x === 'string') return safeText(x);
//                  if (x && x.text) return safeText(x.text);
//                  return safeText(x);
//                })
//                .filter(x => x);
//            }
//
//            const stepsRaw = c.recipeInstructions;
//
//            let steps = [];
//
//            function pushStep(value) {
//              const cleaned = safeText(value);
//              if (!cleaned) return;
//
//              if (!steps.includes(cleaned)) {
//                steps.push(cleaned);
//              }
//            }
//
//            function collectSteps(node) {
//              if (!node) return;
//
//              if (typeof node === 'string') {
//                pushStep(node);
//                return;
//              }
//
//              if (Array.isArray(node)) {
//                for (const item of node) {
//                  collectSteps(item);
//                }
//                return;
//              }
//
//              if (node.text) {
//                pushStep(node.text);
//              }
//
//              if (node.itemListElement) {
//                collectSteps(node.itemListElement);
//              }
//
//              if (node.steps) {
//                collectSteps(node.steps);
//              }
//            }
//
//            collectSteps(stepsRaw);
//
//            const hasEnoughData =
//              title.length > 0 ||
//              ingredients.length >= 3 ||
//              steps.length >= 2;
//
//            if (hasEnoughData) {
//              return JSON.stringify({
//                kind: 'recipe',
//                title: title,
//                ingredients: ingredients,
//                steps: steps,
//                sourceUrl: (location && location.href) ? location.href : ''
//              });
//            }
//          }
//        }
//
//      } catch (e) {}
//    }
//
//  } catch (e) {}
  
    const title =
      document.querySelector('meta[property="og:title"]')?.getAttribute('content') ||
      document.querySelector('h1')?.innerText ||
      document.title ||
      '';

    const text = getCleanVisibleText(${hard ? 'true' : 'false'});

    return JSON.stringify({
      kind: 'text',
      title: normalizeText(title),
      text: normalizeText(text),
      sourceUrl: (location && location.href) ? location.href : ''
    });
  } catch (e) {
    const text = (document.body && document.body.innerText) ? document.body.innerText : '';
    return JSON.stringify({
      kind: 'text',
      title: '',
      text: normalizeText(text),
      sourceUrl: (location && location.href) ? location.href : ''
    });
  }
})();
''';



  // ---------------------------
  //  UI
  // ---------------------------

  Widget _buildUrlInput() {
    if (!widget.embedded) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lim inn lenke til oppskriften',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vi henter ingredienser og fremgangsmåte automatisk fra nettsiden.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
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
                label: const Text('Last inn'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusMessage() {
    if (_isImporting) return 'Importerer…';
    if (_isExtracting) return 'Henter oppskrift…';
    if (_isLoading) return 'Laster side…';
    return '';
  }

  bool get _isBusy => _isLoading || _isExtracting || _isImporting;

  Widget _buildBody() {
    return Stack(
      children: [
        Column(
          children: [
            _buildUrlInput(),
            Expanded(
              child: _currentUrl.isNotEmpty
                  ? WebViewWidget(controller: _controller)
                  : Container(
                color: Colors.grey.shade50,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Lim inn en lenke og trykk Last inn',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isBusy)
          AbsorbPointer(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _getStatusMessage(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Importer oppskrift')),
      body: body,
    );
  }
}
