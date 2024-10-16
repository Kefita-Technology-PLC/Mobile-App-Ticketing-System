// ignore_for_file: prefer_const_constructors

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ticketingmobile_system/Pages/Ticketing_HomePage.dart';

import '../Reusable-Components/Reusable_Background.dart';
import '../Reusable-Components/Reusable_LoginField.dart';
import '../Reusable-Components/Reusable_Logo.dart';
import '../Reusable-Constants/constant.dart';
import 'Admin_HomePage.dart';
import 'Ticketing_Page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userBox = await Hive.openBox('users');
  final userExistsLocally = userBox.values.isNotEmpty;
  runApp(MyApp(userExistsLocally: userExistsLocally));
}

class MyApp extends StatelessWidget {
  final bool userExistsLocally;

  const MyApp({super.key, required this.userExistsLocally});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Poppins'),
      debugShowCheckedModeBanner: false,
      title: 'User Login',
      home: userExistsLocally ? TicketingPage() : UserLogin(),
    );
  }
}

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  _UserLoginState createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<bool> _checkLocalUser(String phone, String password) async {
    final userBox = await Hive.openBox('users');
    final hashedPassword = _hashPassword(password);

    for (var i = 0; i < userBox.length; i++) {
      final user = userBox.getAt(i);
      if (user['phone_no'] == phone && user['password'] == hashedPassword) {
        return true;
      }
    }
    return false;
  }

Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();
      bool userExistsLocally = await _checkLocalUser(phone, password);

      if (userExistsLocally) {
        final userBox = await Hive.openBox('users');
        final user = userBox.values.firstWhere(
          (u) => (u as Map)['phone_no'] == phone,
          orElse: () => null,
        );

        if (user != null) {
          final bool isAdmin = user['isAdmin'] ?? false;
          print('Logging in offline with local storage data.');
          if (await _isServerReachable()) {
            final latestToken =
                await _fetchLatestTokenFromServer(phone, password);
            if (latestToken != null) {
              await _updateOrInsertUserInHive(
                  phone, latestToken, password, isAdmin);
            }
          }

          _navigateToHome(isAdmin); 
          return;
        }
      }
      try {
        final response = await http.post(
          Uri.parse('http://localhost:8000/api/login'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8'
          },
          body: jsonEncode(
              <String, dynamic>{'phone_no': phone, 'password': password}),
        );

        print('Server login response status: ${response.statusCode}');
        print('Server login response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final token = data['token'];
          final bool isAdmin = data['is_admin'] ?? false;
          await _updateOrInsertUserInHive(phone, token, password, isAdmin);

          print('Logging in online with server data.');
          _navigateToHome(isAdmin); 
        } else {
          _showErrorDialog('User doesn\'t exist');
        }
      } catch (e) {
        print('An error occurred: ${e.toString()}');
        _showErrorDialog('Connection error occurred');
      }
    }
  }

  Future<bool> _isServerReachable() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:8000/api/ping'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  Future<String?> _fetchLatestTokenFromServer(
      String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(
            <String, dynamic>{'phone_no': phone, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
      }
    } catch (e) {
      print('Error fetching token: $e');
    }
    return null; 
  }

  Future<void> _updateOrInsertUserInHive(
      String phone, String token, String password, bool isAdmin) async {
    final userBox = await Hive.openBox('users');
    final hashedPassword = _hashPassword(password);
    final existingUser = userBox.values.firstWhere(
      (u) => (u as Map)['phone_no'] == phone,
      orElse: () => null,
    );

    if (existingUser == null) {
      print('Storing new user in local storage.');
      await userBox.add({
        'phone_no': phone,
        'token': token,
        'password': hashedPassword,
        'isAdmin': isAdmin
      });
    } else {
      print('Updating existing user in local storage.');
      final userIndex = userBox.values.toList().indexOf(existingUser);
      await userBox.putAt(userIndex, {
        'phone_no': phone,
        'token': token,
        'password': hashedPassword,
        'isAdmin': isAdmin
      });
    }
  }

  void _navigateToHome(bool isAdmin) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isAdmin ? AdminHomePage() : TicketingHomepage(),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ReusableBackground(),
            ReusableLogo(),
            Positioned.fill(
              top: 150,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 80),
                      Center(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Welcome Back', style: mainStyle))),
                      SizedBox(height: 30),
                      ReusableLoginField(
                        controller: _phoneController,
                        text: 'Enter your Phone Number',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                        obscureText: false,
                        type: TextInputType.phone,
                      ),
                      SizedBox(height: 20),
                      ReusableLoginField(
                        controller: _passwordController,
                        text: 'Enter Password',
                        obscureText: !_isPasswordVisible,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                        type: TextInputType.text,
                      ),
                      SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          height: 45,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: Color(0XFF3D8BFF),
                          ),
                          child: TextButton(
                            onPressed: _login,
                            child: Text('Login',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15)),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
