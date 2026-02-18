import 'package:flutter/material.dart';

import 'import_from_text_screen.dart';
import 'import_from_url_screen.dart';

/// Screen for importing recipes. Shows tabs only when no import method is preselected.
class ImportRecipeScreen extends StatefulWidget {
  const ImportRecipeScreen({
    super.key,
    this.initialTab,
  });

  final int? initialTab;

  @override
  State<ImportRecipeScreen> createState() => _ImportRecipeScreenState();
}

class _ImportRecipeScreenState extends State<ImportRecipeScreen>
    with SingleTickerProviderStateMixin {
    TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab == null) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

    @override
    void dispose() {
      _tabController?.dispose();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    final bool showTabs = widget.initialTab == null;

    if (!showTabs) {
      final bool showUrl = widget.initialTab == 1;
      return Scaffold(
        appBar: AppBar(
          title: Text(showUrl ? 'Importer fra URL' : 'Importer fra tekst'),
        ),
        body: showUrl
            ? const ImportFromUrlScreen(initialUrl: '', embedded: true)
            : const ImportFromTextScreen(embedded: true),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Importer oppskrift'),
        bottom: TabBar(
          controller: _tabController!,
          tabs: const [
            Tab(text: 'Fra tekst'),
            Tab(text: 'Fra URL'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: const [
          ImportFromTextScreen(embedded: true),
          ImportFromUrlScreen(initialUrl: '', embedded: true),
        ],
      ),
    );
  }
}
