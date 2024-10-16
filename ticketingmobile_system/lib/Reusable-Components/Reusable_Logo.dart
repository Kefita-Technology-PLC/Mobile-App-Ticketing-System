import 'package:flutter/material.dart';

class ReusableLogo extends StatelessWidget {
  const ReusableLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 15,
      left: 15,
      child: Image.asset(
        'Image/ticket-logo.png',
        width: 180,
      ),
    );
  }
}
