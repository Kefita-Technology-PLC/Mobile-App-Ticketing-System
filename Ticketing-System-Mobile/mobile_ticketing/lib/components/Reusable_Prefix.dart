import 'package:flutter/material.dart';

import '../Constants/constants.dart';

class ReusablePrefix extends StatelessWidget {
  final String? text;
  ReusablePrefix({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [Text(text.toString(), style: prefix)],
      ),
    );
  }
}
