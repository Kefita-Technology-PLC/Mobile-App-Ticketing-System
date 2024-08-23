import 'package:flutter/material.dart';

import '../screens/Admin_Report.dart';
import '../screens/Admin_User.dart';

class ReusableAdminButton extends StatelessWidget {
  final String? text;
  ReusableAdminButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Color(0XFF3D8BFF),
          borderRadius: BorderRadius.circular(7),
        ),
        child: TextButton(
          onPressed: () {
            _navigateBasedOnText(context);
          },
          child: Text(
            text.toString(),
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ),
    );
  }

  void _navigateBasedOnText(BuildContext context) {
    if (text == "Reporting Page ->") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminReport()),
      );
    } else if (text == "Users Information ->") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LocalStoragePage()),
      );
    }
  }
}
