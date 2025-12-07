import 'package:flutter/material.dart';

import '../features/calculators/screens/calculators_screen.dart';
import 'import_from_text_screen.dart';
import 'my_recipes_screen.dart';

/// Home screen for the Quant app - entry point with main actions.
class QuantHomeScreen extends StatelessWidget {
  const QuantHomeScreen({super.key});

  static const Color _backgroundColor = Color(0xfff7f4ef);
  static const Color _textColor = Color(0xff1f140f);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Quant'),
      ),
      body: const _QuantHomeBody(),
    );
  }
}

class _QuantHomeBody extends StatelessWidget {
  const _QuantHomeBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _HeaderSection(),
          SizedBox(height: 32),
          _MainActions(),
          SizedBox(height: 40),
          _RecentSection(),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Velkommen',
          style: textTheme.labelMedium?.copyWith(
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
            color: QuantHomeScreen._textColor.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Quant',
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: QuantHomeScreen._textColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Lagre, organiser og perfeksjoner oppskriftene dine.',
          style: textTheme.bodyLarge?.copyWith(
            color: QuantHomeScreen._textColor.withOpacity(0.85),
          ),
        ),
      ],
    );
  }
}

class _MainActions extends StatelessWidget {
  const _MainActions();

  void _showPlaceholderSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionCard(
          title: 'Mine oppskrifter',
          subtitle: 'Bla gjennom, rediger og organiser samlingen din.',
          icon: Icons.book_outlined,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyRecipesScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'Importer oppskrift',
          subtitle: 'Lim inn tekst eller filer for å legge til nye oppskrifter.',
          icon: Icons.content_paste,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ImportFromTextScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'Kalkulatorer',
          subtitle: 'Juster hydrering, gjæring og mer.',
          icon: Icons.calculate_outlined,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CalculatorsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Color cardColor = isPrimary
        ? QuantHomeScreen._textColor.withOpacity(0.1)
        : Colors.white;
    final Color borderColor = QuantHomeScreen._textColor.withOpacity(0.15);

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: QuantHomeScreen._textColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: QuantHomeScreen._textColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: QuantHomeScreen._textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: QuantHomeScreen._textColor.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: QuantHomeScreen._textColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context) {
    final recentItems = const [
      'Bolognese (example)',
      '70% hydration pizza dough (example)',
      'Chocolate chip cookies (example)',
    ];

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nylig vist',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: QuantHomeScreen._textColor,
          ),
        ),
        const SizedBox(height: 12),
        ...recentItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '• $item',
              style: textTheme.bodyMedium?.copyWith(
                color: QuantHomeScreen._textColor.withOpacity(0.85),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

