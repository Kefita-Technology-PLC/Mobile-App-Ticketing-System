// ignore_for_file: prefer_const_constructors

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Components/Reusable_background.dart';
import '../Components/Reusable_loginField.dart';
import '../Components/Reusable_logo.dart';
import '../Constants/constants.dart';
import 'Admin_Home.dart';
import 'Ticket_Page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');

  bool userExistsLocally = false;
  if (token != null) {
    final userBox = await Hive.openBox('users');
    userExistsLocally = userBox.values.any((user) => user['token'] == token);
  }

  runApp(MyApp(userExistsLocally: userExistsLocally, token: token));
}

class MyApp extends StatelessWidget {
  final bool userExistsLocally;
  final String? token;

  const MyApp({super.key, required this.userExistsLocally, this.token});

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
  final TextEditingController _emailController = TextEditingController();
  bool _isPasswordVisible = false;

  final FlutterSecureStorage _storage = FlutterSecureStorage();

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
      final phone =
          _phoneController.text.trim(); // Trim spaces from phone input
      final password =
          _passwordController.text.trim(); // Trim spaces from password input

      // First, check if the user exists locally
      bool userExistsLocally = await _checkLocalUser(phone, password);

      if (userExistsLocally) {
        // User found in local storage, log in offline
        print('Logging in offline with local storage data.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TicketingPage(),
          ),
        );
        return;
      }

      // If the user does not exist locally, attempt to log in with the server
      try {
        final response = await http.post(
          Uri.parse('http://localhost:8000/api/login'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'phone_no': phone,
            'password': password,
          }),
        );

        print('Server login response status: ${response.statusCode}');
        print('Server login response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data.containsKey('token') && data['token'] != null) {
            final token = data['token'];

            // Save the token to secure storage
            await _storage.write(key: 'auth_token', value: token);

            // Store or update the user data locally
            final userBox = await Hive.openBox('users');
            final hashedPassword = _hashPassword(password);
            final user = {
              'phone_no': phone,
              'token': token,
              'password': hashedPassword,
            };

            // Check if the user already exists locally
            int userIndex = userBox.values
                .toList()
                .indexWhere((u) => (u as Map)['phone_no'] == phone);

            if (userIndex == -1) {
              // User does not exist, add new entry
              print('Storing new user in local storage.');
              await userBox.add(user);
            } else {
              // User exists, update the existing entry
              print(
                  'User already exists in local storage. Updating user data.');
              await userBox.putAt(userIndex, user);
            }

            // Log in the user
            print('Logging in online with server data.');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TicketingPage(),
              ),
            );
          } else {
            print('Invalid credentials or missing data.');
            _showErrorDialog('Invalid credentials or missing data');
          }
        } else {
          print('Unexpected server response.');
          _showErrorDialog('Unexpected server response');
        }
      } catch (e) {
        print('An error occurred: ${e.toString()}');
        _showErrorDialog('An error occurred: ${e.toString()}');
      }
    } else {
      print("Form is not validated");
    }
  }

  Future<void> _sendForgotPasswordRequest(String email) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/forgot-password'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'email': email,
        }),
      );

      print('Forgot password response status: ${response.statusCode}');
      print('Forgot password response body: ${response.body}');

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close the email input dialog
        _showSuccessDialog(
            'A password reset link has been sent to your email.');
      } else {
        final data = jsonDecode(response.body);
        final errorMessage =
            data['message'] ?? 'Failed to send the password reset link.';
        Navigator.of(context).pop(); // Close the email input dialog
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close the email input dialog
      _showErrorDialog('An error occurred: ${e.toString()}');
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Forgot Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Enter your Email Address',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                final email = _emailController.text;
                if (email.isNotEmpty) {
                  await _sendForgotPasswordRequest(email);
                  _emailController
                      .clear(); // Clear the input field after submission
                } else {
                  _showErrorDialog('Please enter your email address.');
                }
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
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
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
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
            Positioned.fill(
              child: ReusableBackground(),
            ),
            ReusableLogo(),
            Positioned.fill(
              top: 100,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 80),
                      Center(
                        child: Text('Welcome Back', style: mainStyle),
                      ),
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
                      ),
                      SizedBox(height: 20),
                      ReusableLoginField(
                        controller: _passwordController,
                        text: 'Enter Password',
                        obscureText: !_isPasswordVisible,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
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
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: _showForgotPasswordDialog,
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(fontSize: 12),
                        ),
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
                            child: Text(
                              'Login',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminHomePage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Login as Admin',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
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
