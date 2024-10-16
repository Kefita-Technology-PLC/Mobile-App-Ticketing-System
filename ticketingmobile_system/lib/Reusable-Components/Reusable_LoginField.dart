import 'package:flutter/material.dart';

class ReusableLoginField extends StatelessWidget {
  final String? text;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType type;

  ReusableLoginField({
    required this.text,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: type,
        decoration: InputDecoration(
          fillColor: Color(0XFFFFFFFF),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          hintText: text,
          hintStyle: TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
