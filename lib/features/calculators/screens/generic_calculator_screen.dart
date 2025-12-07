import 'package:flutter/material.dart';

import '../models/calculator_definition.dart';

/// Generic calculator screen that renders fields dynamically based on a CalculatorDefinition.
class GenericCalculatorScreen extends StatefulWidget {
  const GenericCalculatorScreen({
    super.key,
    required this.definition,
  });

  final CalculatorDefinition definition;

  @override
  State<GenericCalculatorScreen> createState() => _GenericCalculatorScreenState();
}

class _GenericCalculatorScreenState extends State<GenericCalculatorScreen> {
  final Map<String, dynamic> _fieldValues = {};
  final Map<String, TextEditingController> _textControllers = {};
  String _result = '';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Initialize field values with defaults
    for (final field in widget.definition.fields) {
      if (field.type == CalculatorFieldType.number) {
        _textControllers[field.id] = TextEditingController(
          text: field.defaultValue?.toString() ?? '',
        );
        if (field.defaultValue != null) {
          _fieldValues[field.id] = field.defaultValue;
        }
      } else {
        _fieldValues[field.id] = field.defaultValue ?? (field.options?.isNotEmpty == true ? field.options!.first : '');
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.definition.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.definition.description.isNotEmpty) ...[
              Text(
                widget.definition.description,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
            ],
            ...widget.definition.fields.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildField(field),
                )),
            if (!_hasLiveUpdates()) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _onCalculate,
                  child: const Text('Beregn'),
                ),
              ),
            ],
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Resultat',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _result,
                  style: textTheme.bodyLarge,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(CalculatorFieldDefinition field) {
    switch (field.type) {
      case CalculatorFieldType.number:
        return _buildNumberField(field);
      case CalculatorFieldType.dropdown:
        return _buildDropdownField(field);
      case CalculatorFieldType.slider:
        return _buildSliderField(field);
    }
  }

  Widget _buildNumberField(CalculatorFieldDefinition field) {
    final controller = _textControllers[field.id]!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: textTheme.labelLarge,
        ),
        if (field.helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            field.helpText!,
            style: textTheme.bodySmall?.copyWith(
              color: textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Skriv inn ${field.label.toLowerCase()}',
            suffixText: field.unit,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => _handleFieldChange(field, value),
        ),
      ],
    );
  }

  Widget _buildDropdownField(CalculatorFieldDefinition field) {
    final textTheme = Theme.of(context).textTheme;
    final currentValue = _fieldValues[field.id]?.toString() ?? field.options?.first ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: textTheme.labelLarge,
        ),
        if (field.helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            field.helpText!,
            style: textTheme.bodySmall?.copyWith(
              color: textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          items: field.options?.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _handleFieldChange(field, value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSliderField(CalculatorFieldDefinition field) {
    final textTheme = Theme.of(context).textTheme;
    final currentValue = (_fieldValues[field.id] as num?)?.toDouble() ?? field.min ?? 0.0;
    final min = field.min ?? 0.0;
    final max = field.max ?? 100.0;
    final step = field.step ?? 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.label}: ${currentValue.toStringAsFixed(step < 1 ? 1 : 0)}${field.unit != null ? ' ${field.unit}' : ''}',
          style: textTheme.labelLarge,
        ),
        if (field.helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            field.helpText!,
            style: textTheme.bodySmall?.copyWith(
              color: textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Slider(
          value: currentValue.clamp(min, max),
          min: min,
          max: max,
          divisions: step > 0 ? ((max - min) / step).round() : null,
          label: '${currentValue.toStringAsFixed(step < 1 ? 1 : 0)}${field.unit != null ? ' ${field.unit}' : ''}',
          onChanged: (value) => _handleFieldChange(field, value),
        ),
      ],
    );
  }

  /// Returns true if all number fields have onFieldChanged callbacks (live updates enabled).
  bool _hasLiveUpdates() {
    final numberFields = widget.definition.fields
        .where((field) => field.type == CalculatorFieldType.number)
        .toList();
    
    if (numberFields.isEmpty) return false;
    
    // All number fields must have onFieldChanged for live updates
    return numberFields.every((field) => field.onFieldChanged != null);
  }

  void _handleFieldChange(CalculatorFieldDefinition field, dynamic newValue) {
    if (_isUpdating) return;

    // Update the changed field first
    setState(() {
      if (field.type == CalculatorFieldType.number) {
        final numValue = double.tryParse(newValue.toString());
        if (numValue != null) {
          _fieldValues[field.id] = numValue;
        } else if (newValue.toString().isEmpty) {
          _fieldValues.remove(field.id);
        }
      } else {
        _fieldValues[field.id] = newValue;
      }
    });

    // Call onFieldChanged callback if provided
    if (field.onFieldChanged != null) {
      _isUpdating = true;
      // Create a mutable map that the callback can modify
      final allValues = Map<String, dynamic>.from(_fieldValues);
      
      // Call the callback - it can modify allValues to update other fields
      field.onFieldChanged!(field.id, newValue, allValues);
      
      // Apply any updates the callback made to other fields
      final updatesToApply = <String, dynamic>{};
      final fieldsToClear = <String>[];
      
      for (final otherField in widget.definition.fields) {
        if (otherField.id != field.id && 
            otherField.type == CalculatorFieldType.number) {
          if (allValues.containsKey(otherField.id)) {
            final updatedValue = allValues[otherField.id];
            final currentValue = _fieldValues[otherField.id];
            
            // Always update if value is different or didn't exist
            if (currentValue == null || updatedValue != currentValue) {
              updatesToApply[otherField.id] = updatedValue;
            }
          } else {
            // Field was removed (cleared) - clear the controller too
            if (_fieldValues.containsKey(otherField.id)) {
              fieldsToClear.add(otherField.id);
            }
          }
        }
      }
      
      // Apply updates in a single setState
      if (updatesToApply.isNotEmpty || fieldsToClear.isNotEmpty) {
        setState(() {
          // Apply value updates
          for (final entry in updatesToApply.entries) {
            _fieldValues[entry.key] = entry.value;
            final controller = _textControllers[entry.key];
            if (controller != null) {
              final numValue = entry.value as num;
              controller.text = numValue.toStringAsFixed(
                numValue % 1 == 0 ? 0 : 1
              );
            }
          }
          
          // Clear removed fields
          for (final fieldId in fieldsToClear) {
            _fieldValues.remove(fieldId);
            final controller = _textControllers[fieldId];
            if (controller != null) {
              controller.clear();
            }
          }
        });
      }
      
      _isUpdating = false;
    }
  }

  void _onCalculate() {
    // Validate number fields
    for (final field in widget.definition.fields) {
      if (field.type == CalculatorFieldType.number) {
        final value = _fieldValues[field.id]?.toString() ?? '';
        if (value.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${field.label} er påkrevd')),
          );
          return;
        }
        if (double.tryParse(value) == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${field.label} må være et gyldig tall')),
          );
          return;
        }
      }
    }

    // Call calculate function if provided, otherwise echo
    final result = widget.definition.calculate != null
        ? widget.definition.calculate!(_fieldValues)
        : _echoInputs();

    setState(() {
      _result = result;
    });
  }

  String _echoInputs() {
    final parts = <String>[];
    for (final field in widget.definition.fields) {
      final value = _fieldValues[field.id];
      if (value != null && value.toString().isNotEmpty) {
        final unit = field.unit != null ? ' ${field.unit}' : '';
        parts.add('${field.label}: $value$unit');
      }
    }
    return parts.isEmpty ? 'Skriv inn verdier for å beregne.' : parts.join('\n');
  }
}

