import 'package:flutter/material.dart';

enum UnitConverterMode {
  temperature,
  volume,
  weight,
}

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  static const Color _backgroundColor = Color(0xfff7f4ef);
  static const Color _textColor = Color(0xff1f140f);

  UnitConverterMode _mode = UnitConverterMode.temperature;

  late final Map<String, TextEditingController> _controllers;
  String? _activeUnitKey;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _controllers = <String, TextEditingController>{
      'c': TextEditingController(),
      'f': TextEditingController(),
      'k': TextEditingController(),
      'ml': TextEditingController(),
      'dl': TextEditingController(),
      'l': TextEditingController(),
      'krm': TextEditingController(),
      'ts': TextEditingController(),
      'ss': TextEditingController(),
      'cup': TextEditingController(),
      'floz': TextEditingController(),
      'mg': TextEditingController(),
      'g': TextEditingController(),
      'kg': TextEditingController(),
      'oz': TextEditingController(),
      'lb': TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Enheter'),
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
            Text(
              'Korrekte konverteringer mellom enheter.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: _textColor.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<UnitConverterMode>(
              segments: const [
                ButtonSegment<UnitConverterMode>(
                  value: UnitConverterMode.temperature,
                  label: Text('Temp'),
                ),
                ButtonSegment<UnitConverterMode>(
                  value: UnitConverterMode.volume,
                  label: Text('Volum'),
                ),
                ButtonSegment<UnitConverterMode>(
                  value: UnitConverterMode.weight,
                  label: Text('Vekt'),
                ),
              ],
              selected: <UnitConverterMode>{_mode},
              onSelectionChanged: (Set<UnitConverterMode> selection) {
                setState(() {
                  _mode = selection.first;
                  _activeUnitKey = null;
                  _clearVisibleFields();
                });
              },
            ),
            const SizedBox(height: 24),
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
                      _sectionTitle(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._buildFieldsForCurrentMode(),
                  ],
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
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _textColor.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Skriv inn en verdi i et av feltene for å oppdatere de andre automatisk.',
                        style: theme.textTheme.bodySmall?.copyWith(
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

  String _sectionTitle() {
    if (_mode == UnitConverterMode.temperature) {
      return 'Temperatur';
    }

    if (_mode == UnitConverterMode.volume) {
      return 'Volum';
    }

    return 'Vekt';
  }

  List<Widget> _buildFieldsForCurrentMode() {
    if (_mode == UnitConverterMode.temperature) {
      return <Widget>[
        _buildUnitField(
          unitKey: 'c',
          label: 'Celsius',
          suffix: '°C',
          signed: true,
        ),
        const SizedBox(height: 16),
        _buildUnitField(
          unitKey: 'f',
          label: 'Fahrenheit',
          suffix: '°F',
          signed: true,
        ),
        const SizedBox(height: 16),
        _buildUnitField(
          unitKey: 'k',
          label: 'Kelvin',
          suffix: 'K',
          signed: false,
        ),
      ];
    }

    if (_mode == UnitConverterMode.volume) {
      return <Widget>[
        _buildUnitField(unitKey: 'ml', label: 'Milliliter', suffix: 'ml'),
        const SizedBox(height: 16),
        _buildUnitField(unitKey: 'dl', label: 'Desiliter', suffix: 'dl'),
        const SizedBox(height: 16),
        _buildUnitField(unitKey: 'l', label: 'Liter', suffix: 'l'),
        const SizedBox(height: 16),
        _buildUnitField(unitKey: 'krm', label: 'Kryddermål (krm)', suffix: 'krm'),
        const SizedBox(height: 16),
        _buildUnitField(unitKey: 'ts', label: 'Teskje', suffix: 'ts'),
        const SizedBox(height: 16),
        _buildUnitField(unitKey: 'ss', label: 'Spiseskje', suffix: 'ss'),
        const SizedBox(height: 16),
        _buildUnitField(unitKey: 'cup', label: 'Cup (US)', suffix: 'cup'),
        const SizedBox(height: 16),
        _buildUnitField(
          unitKey: 'floz',
          label: 'Fluid ounce (US)',
          suffix: 'fl oz',
        ),
      ];
    }

    return <Widget>[
      _buildUnitField(unitKey: 'mg', label: 'Milligram', suffix: 'mg'),
      const SizedBox(height: 16),
      _buildUnitField(unitKey: 'g', label: 'Gram', suffix: 'g'),
      const SizedBox(height: 16),
      _buildUnitField(unitKey: 'kg', label: 'Kilogram', suffix: 'kg'),
      const SizedBox(height: 16),
      _buildUnitField(unitKey: 'oz', label: 'Ounce (oz)', suffix: 'oz'),
      const SizedBox(height: 16),
      _buildUnitField(unitKey: 'lb', label: 'Pund (lb)', suffix: 'lb'),
    ];
  }

  Widget _buildUnitField({
    required String unitKey,
    required String label,
    required String suffix,
    bool signed = false,
  }) {
    return TextField(
      controller: _controllers[unitKey],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixText: suffix,
      ),
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: signed,
      ),
      onChanged: (String value) => _onUnitChanged(unitKey, value),
    );
  }

  void _onUnitChanged(String unitKey, String rawValue) {
    if (_isUpdating) {
      return;
    }

    _activeUnitKey = unitKey;

    if (rawValue.trim().isEmpty) {
      _clearVisibleFields(except: unitKey);
      return;
    }

    final String normalized = rawValue.trim().replaceAll(',', '.');
    final double? input = double.tryParse(normalized);

    if (input == null) {
      return;
    }

    if (_mode == UnitConverterMode.temperature) {
      _updateTemperatureFields(unitKey, input);
      return;
    }

    if (_mode == UnitConverterMode.volume) {
      _updateFactorFields(
        sourceUnitKey: unitKey,
        input: input,
        factors: <String, double>{
          'ml': 1.0,
          'dl': 100.0,
          'l': 1000.0,
          'krm': 1.0,
          'ts': 5.0,
          'ss': 15.0,
          'cup': 236.5882365,
          'floz': 29.5735295625,
        },
        visibleUnitKeys: <String>[
          'ml',
          'dl',
          'l',
          'krm',
          'ts',
          'ss',
          'cup',
          'floz',
        ],
      );
      return;
    }

    _updateFactorFields(
      sourceUnitKey: unitKey,
      input: input,
      factors: <String, double>{
        'mg': 0.001,
        'g': 1.0,
        'kg': 1000.0,
        'oz': 28.349523125,
        'lb': 453.59237,
      },
      visibleUnitKeys: <String>['mg', 'g', 'kg', 'oz', 'lb'],
    );
  }

  void _updateTemperatureFields(String sourceUnitKey, double input) {
    final double celsius = switch (sourceUnitKey) {
      'c' => input,
      'f' => (input - 32) * 5 / 9,
      'k' => input - 273.15,
      _ => input,
    };

    final Map<String, double> results = <String, double>{
      'c': celsius,
      'f': (celsius * 9 / 5) + 32,
      'k': celsius + 273.15,
    };

    _writeValues(
      values: results,
      visibleUnitKeys: <String>['c', 'f', 'k'],
      sourceUnitKey: sourceUnitKey,
    );
  }

  void _updateFactorFields({
    required String sourceUnitKey,
    required double input,
    required Map<String, double> factors,
    required List<String> visibleUnitKeys,
  }) {
    final double sourceFactor = factors[sourceUnitKey]!;
    final double baseValue = input * sourceFactor;

    final Map<String, double> results = <String, double>{};
    for (final String unitKey in visibleUnitKeys) {
      results[unitKey] = baseValue / factors[unitKey]!;
    }

    _writeValues(
      values: results,
      visibleUnitKeys: visibleUnitKeys,
      sourceUnitKey: sourceUnitKey,
    );
  }

  void _writeValues({
    required Map<String, double> values,
    required List<String> visibleUnitKeys,
    required String sourceUnitKey,
  }) {
    _isUpdating = true;

    for (final String unitKey in visibleUnitKeys) {
      if (unitKey == sourceUnitKey) {
        continue;
      }

      _controllers[unitKey]!.text = _formatNumber(values[unitKey]!);
    }

    _isUpdating = false;
  }

  void _clearVisibleFields({String? except}) {
    _isUpdating = true;

    for (final String unitKey in _visibleUnitKeysForMode(_mode)) {
      if (unitKey == except) {
        continue;
      }
      _controllers[unitKey]!.clear();
    }

    _isUpdating = false;
  }

  List<String> _visibleUnitKeysForMode(UnitConverterMode mode) {
    if (mode == UnitConverterMode.temperature) {
      return <String>['c', 'f', 'k'];
    }

    if (mode == UnitConverterMode.volume) {
      return <String>['ml', 'dl', 'l', 'krm', 'ts', 'ss', 'cup', 'floz'];
    }

    return <String>['mg', 'g', 'kg', 'oz', 'lb'];
  }

  String _formatNumber(double value) {
    final String fixed = value.toStringAsFixed(3);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}