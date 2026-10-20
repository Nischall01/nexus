import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowClear = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool allowClear;

  static final _fmt = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allowClear && value != null)
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => onChanged(null),
              ),
            IconButton(
              tooltip: 'Pick date',
              icon: const Icon(Icons.calendar_today, size: 18),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: value ?? now,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) onChanged(picked);
              },
            ),
          ],
        ),
      ),
      child: Text(
        value == null ? '—' : _fmt.format(value!),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
