import 'package:flutter/material.dart';

import '../features/calculators/screens/calculators_screen.dart';
import 'create_recipe_screen.dart';
import 'my_recipes_screen.dart';
import '../auth/auth_gate.dart';
import '../backend/quant_backend.dart';
import 'inbox_screen.dart';

/// Home screen for the Quant app - entry point with main actions.
class QuantHomeScreen extends StatefulWidget {
  const QuantHomeScreen({super.key});

  static const Color _backgroundColor = Color(0xfff7f4ef);
  static const Color _textColor = Color(0xff1f140f);

  @override
  State<QuantHomeScreen> createState() => _QuantHomeScreenState();

}

class _QuantHomeScreenState extends State<QuantHomeScreen> {
  int _inboxCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInboxCount();
  }

  Future<void> _loadInboxCount() async {
    try {
      final count = await quantBackend.getInboxCount();
      if (!mounted) return;
      setState(() => _inboxCount = count);
    } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantHomeScreen._backgroundColor,
      appBar: AppBar(
        title: const Text('Quant'),
        actions: [
          // 📬 Inbox icon
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.mail_outline),
                onPressed: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const InboxScreen()),
                  );

                  if (!mounted) return;

                  if (changed == true) {
                    await _loadInboxCount();
                  }
                },

              ),
              if (_inboxCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_inboxCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // logout-knappen din (som før)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await tokenStore.clear();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                    (_) => false,
              );
            },
          ),
        ],
      ),
      body: const _QuantHomeBody(),
    );
  }
}


//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      backgroundColor: _backgroundColor,
//      appBar: AppBar(
//        title: const Text('Quant'),
//        actions: [
//          IconButton(
//            icon: const Icon(Icons.logout),
//            onPressed: () async {
//              await tokenStore.clear();
//              if (!context.mounted) return;
//              Navigator.of(context).pushAndRemoveUntil(
//                MaterialPageRoute(builder: (_) => const AuthGate()),
//                    (_) => false,
//              );
//            },
//          ),
//        ],
//      ),
//      body: const _QuantHomeBody(),
//    );
//  }
//}

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
              MaterialPageRoute(builder: (_) => const MyRecipesScreen()),
            );
          },
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'Lag ny oppskrift',
          subtitle: 'Manuelt, import eller fra verktøy.',
          icon: Icons.add_circle_outline,
          isPrimary: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
            );
          },
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'Verktøy',
          subtitle: 'Kalkulatorer og hjelpemidler.',
          icon: Icons.handyman_outlined,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculatorsScreen()),
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

    final Color cardColor = Colors.white;
    final Color borderColor = isPrimary
        ? QuantHomeScreen._textColor.withOpacity(0.35)
        : QuantHomeScreen._textColor.withOpacity(0.15);

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
