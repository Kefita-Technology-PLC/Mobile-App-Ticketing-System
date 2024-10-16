import 'package:flutter/material.dart';

class ReusableBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(0.35),
          BlendMode.dstATop,
        ),
        child: Image.asset(
          'Image/transport-road.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
