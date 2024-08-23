import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Constants/constants.dart';

class ReusableSelection extends StatelessWidget {
  final String title;
  final String hintText;
  final void Function(String) onSelectionChanged;
  final List<String>? options;

  ReusableSelection({
    required this.title,
    required this.hintText,
    required this.onSelectionChanged,
    this.options,
    required void Function() onCustomTimePicker,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text(
            title,
            style: prefix,
          ),
          SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                readOnly: true,
                decoration: InputDecoration(
                  suffixIcon: GestureDetector(
                    onTap: () => _showPopup(context),
                    child: Icon(Icons.expand_more),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  hintText: hintText,
                  hintStyle: textField,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPopup(BuildContext context) {
    if (title == 'Date:') {
      _selectDate(context);
    } else if (title == 'Time:') {
      _selectTime(context);
    } else if (options != null) {
      _showMenu(context);
    }
  }

  void _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
      onSelectionChanged(formattedDate);
    }
  }

  void _selectTime(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => CustomTimePicker(
        onTimeSelected: (time) {
          onSelectionChanged(time);
        },
      ),
    );
  }

  void _showMenu(BuildContext context) async {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          offset.dx, offset.dy + renderBox.size.height, 0, 0),
      items: options!
          .map((option) => PopupMenuItem<String>(
                value: option,
                child: Text(option),
              ))
          .toList(),
      elevation: 8.0,
    );

    if (selected != null) {
      onSelectionChanged(selected);
    }
  }
}

class CustomTimePicker extends StatefulWidget {
  final void Function(String) onTimeSelected;

  CustomTimePicker({required this.onTimeSelected});

  @override
  _CustomTimePickerState createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  int _hour = 0;
  int _minute = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Hour'),
              ),
              Expanded(
                child: Text('Minute'),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: NumberPicker(
                  value: _hour,
                  minValue: 0,
                  maxValue: 23,
                  onChanged: (value) {
                    setState(() {
                      _hour = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: NumberPicker(
                  value: _minute,
                  minValue: 0,
                  maxValue: 59,
                  onChanged: (value) {
                    setState(() {
                      _minute = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            String formattedTime =
                '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';
            widget.onTimeSelected(formattedTime);
            Navigator.pop(context);
          },
          child: Text('OK'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}

class NumberPicker extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  NumberPicker({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        diameterRatio: 1.5,
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            if (index < minValue || index > maxValue) {
              return null;
            }
            return Center(
              child: Text(
                index.toString(),
                style: TextStyle(fontSize: 24),
              ),
            );
          },
          childCount: maxValue - minValue + 1,
        ),
      ),
    );
  }
}
