import 'package:flutter/material.dart';

import '../Reusable-Components/Reusable_RoutingButton.dart';
import '../Reusable-Components/Reusable_Background.dart';
import '../Reusable-Components/Reusable_Logo.dart';
import '../Reusable-Constants/constant.dart';

void main() {
  runApp(const AdminHomePage());
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
              ReusableBackground(),
              const ReusableLogo(),
              Column(
                children: [
                  const SizedBox(height: 100),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Admin DashBoard',
                      style: titles,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ReusableAdminButton(
                                    text: 'Reporting Page',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ReusableAdminButton(
                                    text: 'Users Information',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ReusableAdminButton(
                                    text: 'Stored Informations',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
