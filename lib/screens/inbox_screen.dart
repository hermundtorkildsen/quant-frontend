import 'package:flutter/material.dart';
import '../backend/quant_backend.dart'; // gir access til global quantBackend
import '../models/recipe.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> _shares = [];
  bool _loading = true;
  bool _loadedOnce = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final shares = await quantBackend.getInbox();
      if (!mounted) return;
      setState(() {
        _shares = shares;
        _loading = false;
        _loadedOnce = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadedOnce = true;
      });
    }
  }

  Future<void> _accept(String shareId) async {
    final Recipe recipe = await quantBackend.acceptShare(shareId);

    setState(() {
      _shares.removeWhere((s) => s['id'] == shareId);
    });

    _changed = true;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Oppskrift lagt til i Mine oppskrifter")),
    );
  }

  Future<void> _openShareDetails(Map<String, dynamic> share) async {
    final shareId = share['id'] as String;
    final fromUsername = (share['fromUsername'] ?? '').toString();
    final message = (share['message'] ?? '').toString().trim();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fra $fromUsername",
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                // Hele meldingen (scrollbar om den er lang)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: Text(
                      message.isEmpty ? "Ingen melding" : message,
                      style: Theme.of(sheetContext).textTheme.bodyMedium,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _decline(shareId);
                        },
                        child: const Text("Avslå"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _accept(shareId);
                        },
                        child: const Text("Lagre"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _decline(String shareId) async {
    await quantBackend.declineShare(shareId);

    setState(() {
      _shares.removeWhere((s) => s['id'] == shareId);
    });

    _changed = true;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Deling avslått")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && !_loadedOnce) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_changed); // send true/false tilbake til Home
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Delte oppskrifter"),
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
        ),
        body: _shares.isEmpty
            ? const Center(child: Text("Ingen delte oppskrifter akkurat nå."))
            : ListView.builder(
          itemCount: _shares.length,
          itemBuilder: (context, index) {
            final share = _shares[index];

            return Dismissible(
              key: ValueKey(share['id']),
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      "Aksepter",
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),

              secondaryBackground: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Avslå",
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.close, color: Colors.red.shade700),
                  ],
                ),
              ),

              confirmDismiss: (direction) async {
                final shareId = share['id'] as String;

                if (direction == DismissDirection.startToEnd) {
                  await _accept(shareId);
                  return true;
                }

                if (direction == DismissDirection.endToStart) {
                  await _decline(shareId);
                  return true;
                }

                return false;
              },
              onDismissed: (direction) { },

              child: Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("Fra ${share['fromUsername']}"),
                  subtitle: Text(
                    (share['message'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openShareDetails(share),
                ),
              ),
            );
          },
        ),
      ),
    );

  }
}
