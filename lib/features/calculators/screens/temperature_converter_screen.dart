import 'package:flutter/material.dart';

/// Simple temperature converter screen (Celsius ↔ Fahrenheit).
class TemperatureConverterScreen extends StatefulWidget {
  const TemperatureConverterScreen({
    super.key,
    required this.title,
    this.description,
  });

  final String title;
  final String? description;

  @override
  State<TemperatureConverterScreen> createState() =>
      _TemperatureConverterScreenState();
}

class _TemperatureConverterScreenState
    extends State<TemperatureConverterScreen> {
  final TextEditingController _celsiusController = TextEditingController();
  final TextEditingController _fahrenheitController = TextEditingController();
  bool _updatingFromCelsius = false;
  bool _updatingFromFahrenheit = false;

  @override
  void dispose() {
    _celsiusController.dispose();
    _fahrenheitController.dispose();
    super.dispose();
  }

  void _onCelsiusChanged(String value) {
    if (_updatingFromFahrenheit) return;

    final celsius = double.tryParse(value);
    if (celsius != null) {
      _updatingFromCelsius = true;
      final fahrenheit = (celsius * 9 / 5) + 32;
      _fahrenheitController.text = fahrenheit.toStringAsFixed(1);
      _updatingFromCelsius = false;
    } else if (value.isEmpty) {
      _updatingFromCelsius = true;
      _fahrenheitController.clear();
      _updatingFromCelsius = false;
    }
  }

  void _onFahrenheitChanged(String value) {
    if (_updatingFromCelsius) return;

    final fahrenheit = double.tryParse(value);
    if (fahrenheit != null) {
      _updatingFromFahrenheit = true;
      final celsius = (fahrenheit - 32) * 5 / 9;
      _celsiusController.text = celsius.toStringAsFixed(1);
      _updatingFromFahrenheit = false;
    } else if (value.isEmpty) {
      _updatingFromFahrenheit = true;
      _celsiusController.clear();
      _updatingFromFahrenheit = false;
    }
  }

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
            if (widget.description != null && widget.description!.isNotEmpty)
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
                  color: const Color(0xff1f140f).withOpacity(0.15),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temperatur',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1f140f),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _celsiusController,
                      decoration: const InputDecoration(
                        labelText: 'Celsius (°C)',
                        border: OutlineInputBorder(),
                        suffixText: '°C',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      onChanged: _onCelsiusChanged,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Icon(
                        Icons.swap_vert,
                        color: const Color(0xff1f140f).withOpacity(0.4),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _fahrenheitController,
                      decoration: const InputDecoration(
                        labelText: 'Fahrenheit (°F)',
                        border: OutlineInputBorder(),
                        suffixText: '°F',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      onChanged: _onFahrenheitChanged,
                    ),
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
                  color: const Color(0xff1f140f).withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xff1f140f).withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Skriv inn en verdi i et av feltene for å konvertere automatisk.',
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xff1f140f).withOpacity(0.75),
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



