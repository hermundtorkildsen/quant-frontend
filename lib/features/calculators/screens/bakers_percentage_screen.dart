import 'package:flutter/material.dart';

/// Baker's percentage calculator - calculates ingredient weights from flour and percentages.
class BakersPercentageScreen extends StatefulWidget {
  const BakersPercentageScreen({
    super.key,
    required this.title,
    this.description,
  });

  final String title;
  final String? description;

  @override
  State<BakersPercentageScreen> createState() =>
      _BakersPercentageScreenState();
}

class _BakersPercentageScreenState extends State<BakersPercentageScreen> {
  final TextEditingController _flourController = TextEditingController(
    text: '500',
  );
  final TextEditingController _hydrationController = TextEditingController(
    text: '65',
  );
  final TextEditingController _saltController = TextEditingController(
    text: '2.5',
  );
  final TextEditingController _yeastController = TextEditingController(
    text: '0.5',
  );

  double? _flourGrams;
  double? _hydrationPercent;
  double? _saltPercent;
  double? _yeastPercent;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _flourController.dispose();
    _hydrationController.dispose();
    _saltController.dispose();
    _yeastController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _flourGrams = double.tryParse(_flourController.text);
      _hydrationPercent = double.tryParse(_hydrationController.text);
      _saltPercent = double.tryParse(_saltController.text);
      _yeastPercent = double.tryParse(_yeastController.text);
    });
  }

  double? get _waterGrams {
    if (_flourGrams == null || _hydrationPercent == null) return null;
    return _flourGrams! * (_hydrationPercent! / 100);
  }

  double? get _saltGrams {
    if (_flourGrams == null || _saltPercent == null) return null;
    return _flourGrams! * (_saltPercent! / 100);
  }

  double? get _yeastGrams {
    if (_flourGrams == null || _yeastPercent == null) return null;
    return _flourGrams! * (_yeastPercent! / 100);
  }

  double? get _totalDoughWeight {
    if (_flourGrams == null) return null;
    final water = _waterGrams ?? 0;
    final salt = _saltGrams ?? 0;
    final yeast = _yeastGrams ?? 0;
    return _flourGrams! + water + salt + yeast;
  }

  static const Color _textColor = Color(0xff1f140f);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.description != null &&
                widget.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  widget.description!,
                  style: textTheme.bodyLarge,
                ),
              ),
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
                      'Inndata',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _flourController,
                      decoration: const InputDecoration(
                        labelText: 'Mel (g)',
                        border: OutlineInputBorder(),
                        suffixText: 'g',
                        helperText: 'Mel er alltid 100%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _calculate(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hydrationController,
                      decoration: const InputDecoration(
                        labelText: 'Hydrering (%)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                        helperText: 'Vann som % av mel',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _calculate(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _saltController,
                      decoration: const InputDecoration(
                        labelText: 'Salt (%)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                        helperText: 'Salt som % av mel',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _calculate(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _yeastController,
                      decoration: const InputDecoration(
                        labelText: 'Gjær (%)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                        helperText: 'Gjær som % av mel',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _calculate(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_flourGrams != null && _flourGrams! > 0)
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
                        'Formel',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ResultRow(
                        label: 'Mel',
                        value: _flourGrams!,
                        unit: 'g',
                        percentage: 100.0,
                      ),
                      if (_waterGrams != null) ...[
                        const SizedBox(height: 8),
                        _ResultRow(
                          label: 'Vann',
                          value: _waterGrams!,
                          unit: 'g',
                          percentage: _hydrationPercent,
                        ),
                      ],
                      if (_saltGrams != null) ...[
                        const SizedBox(height: 8),
                        _ResultRow(
                          label: 'Salt',
                          value: _saltGrams!,
                          unit: 'g',
                          percentage: _saltPercent,
                        ),
                      ],
                      if (_yeastGrams != null) ...[
                        const SizedBox(height: 8),
                        _ResultRow(
                          label: 'Gjær',
                          value: _yeastGrams!,
                          unit: 'g',
                          percentage: _yeastPercent,
                        ),
                      ],
                      if (_totalDoughWeight != null) ...[
                        const Divider(height: 24),
                        _ResultRow(
                          label: 'Total deig',
                          value: _totalDoughWeight!,
                          unit: 'g',
                          isTotal: true,
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
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
                  child: Text(
                    'Skriv inn melvekt for å beregne ingrediensmengder.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: _textColor.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Card(
              color: Colors.white.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: _textColor.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _textColor.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Baker\'s percentage: Alle ingredienser uttrykkes som en prosentandel av melvekten. Mel er alltid 100%.',
                        style: textTheme.bodySmall?.copyWith(
                          color: _textColor.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.unit,
    this.percentage,
    this.isTotal = false,
  });

  final String label;
  final double value;
  final String unit;
  final double? percentage;
  final bool isTotal;

  static const Color _textColor = Color(0xff1f140f);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Format value: remove trailing .0 if whole number, otherwise 1-2 decimals
    final formattedValue = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: _textColor.withOpacity(0.85),
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (percentage != null && !isTotal) ...[
              const SizedBox(width: 8),
              Text(
                '(${percentage!.toStringAsFixed(percentage! % 1 == 0 ? 0 : 1)}%)',
                style: textTheme.bodySmall?.copyWith(
                  color: _textColor.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
        Text(
          '$formattedValue $unit',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
      ],
    );
  }
}

