import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TimePickerSheet extends StatefulWidget {
  final TimeOfDay? initialTime;
  final ValueChanged<TimeOfDay> onSelected;

  const TimePickerSheet({super.key, this.initialTime, required this.onSelected});

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  static const _cycles = 100;
  late int _hour;
  late int _minute;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    final time = widget.initialTime ?? TimeOfDay.now();
    _hour = time.hour == 0 ? 24 : time.hour;
    _minute = time.minute;
    _hourController = FixedExtentScrollController(initialItem: 24 * 50 + _hour - 1);
    _minuteController = FixedExtentScrollController(initialItem: 60 * 50 + _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  Widget _wheel({required int count, required FixedExtentScrollController controller, required ValueChanged<int> onChanged, bool oneBased = false}) {
    return Expanded(
      child: CupertinoPicker.builder(
        scrollController: controller,
        itemExtent: 42,
        selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(),
        childCount: count * _cycles,
        onSelectedItemChanged: (index) => onChanged((index % count) + (oneBased ? 1 : 0)),
        itemBuilder: (_, index) => Center(
          child: Text('${(index % count) + (oneBased ? 1 : 0)}'.padLeft(2, '0'), style: const TextStyle(fontSize: 23)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 340,
        child: Column(children: [
          const SizedBox(height: 18),
          const Text('Выберите время', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Expanded(child: Row(children: [
            _wheel(count: 24, oneBased: true, controller: _hourController, onChanged: (v) => setState(() => _hour = v)),
            const Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
            _wheel(count: 60, controller: _minuteController, onChanged: (v) => setState(() => _minute = v)),
          ])),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () {
                widget.onSelected(TimeOfDay(hour: _hour % 24, minute: _minute));
                Navigator.pop(context);
              },
              child: const Text('Готово'),
            )),
          ),
        ]),
      ),
    );
  }
}
