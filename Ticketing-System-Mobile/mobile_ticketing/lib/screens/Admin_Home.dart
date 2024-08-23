import 'package:flutter/material.dart';
import '../Components/Reusable_background.dart';
import '../Components/Reusable_logo.dart';
import '../Constants/constants.dart';
import '../components/Reusable_AdminButton.dart';

void main() {
  runApp(AdminHomePage());
}

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Poppins'),
      debugShowCheckedModeBanner: false,
      title: 'Admin home page',
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: ReusableBackground(),
              ),
              ReusableLogo(),
              Positioned.fill(
                top: 100,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        'Admin DashBoard',
                        style: titles,
                      ),
                      SizedBox(
                        height: 50,
                      ),
                      ReusableAdminButton(
                        text: 'Reporting Page ->',
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      ReusableAdminButton(text: 'Users Information ->')
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
