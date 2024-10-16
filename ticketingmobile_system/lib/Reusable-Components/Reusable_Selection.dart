import 'package:flutter/material.dart';
import '../Reusable-Constants/constant.dart';

class ReusableSelection extends StatelessWidget {
  final String title;
  final String hintText;
  final void Function(String) onSelectionChanged;
  final List<String>? options;
  final TextStyle? hintTextStyle;
  final Widget? suffixIcon;
  final bool isInputField;
  final TextEditingController? controller; 

  ReusableSelection({
    required this.title,
    required this.hintText,
    required this.onSelectionChanged,
    this.options,
    this.hintTextStyle,
    this.suffixIcon,
    this.isInputField = false,
    this.controller, 
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
                controller: controller, 
                readOnly: !isInputField,
                onChanged: (value) {
                  if (isInputField) {
                    onSelectionChanged(
                        value); 
                  }
                },
                onTap: () {
                  if (!isInputField) {
                    _showPopup(context);
                  }
                },
                decoration: InputDecoration(
                  suffixIcon: suffixIcon != null
                      ? GestureDetector(
                          onTap: () => _showPopup(context),
                          child: Icon(Icons.expand_more),
                        )
                      : null,
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  hintText: hintText,
                  hintStyle: hintTextStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPopup(BuildContext context) {
    if (options != null && options!.isNotEmpty) {
      _showMenu(context);
    }
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
      controller?.text = selected; 
      onSelectionChanged(selected); 
    }
  }
}
