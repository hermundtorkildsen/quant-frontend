import 'package:flutter/material.dart';

import 'import_from_text_screen.dart';
import 'import_from_url_screen.dart';

/// Screen for importing recipes with tabs for different import methods.
class ImportRecipeScreen extends StatefulWidget {
  const ImportRecipeScreen({super.key});

  @override
  State<ImportRecipeScreen> createState() => _ImportRecipeScreenState();
}

class _ImportRecipeScreenState extends State<ImportRecipeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import recipe'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'From text'),
            Tab(text: 'From URL'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ImportFromTextScreen(embedded: true),
          ImportFromUrlScreen(
            initialUrl: 'https://example.com',
            embedded: true,
          ),
        ],
      ),
    );
  }
}

