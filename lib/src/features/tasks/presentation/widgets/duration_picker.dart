import 'package:flutter/material.dart';

/// A selectable duration chip option shown in [CreateTaskSheet].
final class DurationOption {
  const DurationOption({
    required this.label,
    required this.minutes,
    this.isCustom = false,
  });

  final String label;
  final int? minutes;
  final bool isCustom;
}

const List<DurationOption> durationOptions = <DurationOption>[
  DurationOption(label: '15 min', minutes: 15),
  DurationOption(label: '30 min', minutes: 30),
  DurationOption(label: '1 hr', minutes: 60),
  DurationOption(label: '2 hr', minutes: 120),
  DurationOption(label: 'Custom', minutes: null, isCustom: true),
];

enum DurationUnit { minutes, hours }

final class CustomDurationResult {
  const CustomDurationResult({required this.value, required this.unit});

  final int value;
  final DurationUnit unit;

  int get totalMinutes => unit == DurationUnit.hours ? value * 60 : value;
}

/// Dialog for entering a custom task duration in minutes or hours.
class CustomDurationPickerDialog extends StatefulWidget {
  const CustomDurationPickerDialog({
    super.key,
    required this.initialDurationMinutes,
  });

  final int initialDurationMinutes;

  @override
  State<CustomDurationPickerDialog> createState() =>
      _CustomDurationPickerDialogState();
}

class _CustomDurationPickerDialogState
    extends State<CustomDurationPickerDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  DurationUnit _unit = DurationUnit.minutes;

  @override
  void initState() {
    super.initState();
    final int initialMinutes = widget.initialDurationMinutes;
    if (initialMinutes % 60 == 0) {
      _unit = DurationUnit.hours;
      _valueController = TextEditingController(text: '${initialMinutes ~/ 60}');
    } else {
      _unit = DurationUnit.minutes;
      _valueController = TextEditingController(text: '$initialMinutes');
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom duration'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'Enter a number',
              ),
              validator: (String? value) {
                final int? parsed = int.tryParse((value ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DurationUnit>(
              initialValue: _unit,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: const <DropdownMenuItem<DurationUnit>>[
                DropdownMenuItem(
                  value: DurationUnit.minutes,
                  child: Text('Minutes'),
                ),
                DropdownMenuItem(
                  value: DurationUnit.hours,
                  child: Text('Hours'),
                ),
              ],
              onChanged: (DurationUnit? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _unit = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final int value = int.parse(_valueController.text.trim());
    Navigator.of(context).pop(CustomDurationResult(value: value, unit: _unit));
  }
}

String formatDurationLabel(int minutes) {
  if (minutes < 60) return '$minutes min';
  final int hours = minutes ~/ 60;
  final int remainder = minutes % 60;
  if (remainder == 0) return hours == 1 ? '1 hr' : '$hours hr';
  return '$hours hr $remainder min';
}
