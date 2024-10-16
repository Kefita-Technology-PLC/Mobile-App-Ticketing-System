// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../Reusable-Components/Reusable_Background.dart';
import '../Reusable-Components/Reusable_Logo.dart';
import '../Reusable-Constants/constant.dart';

class LocalStoragePage extends StatefulWidget {
  const LocalStoragePage({super.key});

  @override
  _LocalStoragePageState createState() => _LocalStoragePageState();
}

class _LocalStoragePageState extends State<LocalStoragePage> {
  late Future<Box> _userBoxFuture;

  @override
  void initState() {
    super.initState();
    _userBoxFuture = Hive.openBox('users');
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<List<Map<String, dynamic>>> _getStoredUsers(Box userBox) async {
    final List<Map<String, dynamic>> users = [];

    for (var i = 0; i < userBox.length; i++) {
      final value = userBox.getAt(i) as Map<dynamic, dynamic>;

      final phoneNo = value['phone_no'] as String? ?? '';
      final password = value['password'] as String? ?? '';
      final isAdmin = value['isAdmin'] as bool? ?? false;

      users.add({
        'phone_no': phoneNo,
        'password': password,
        'isAdmin': isAdmin,
      });
    }
    return users;
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
              top: 100,
              child: FutureBuilder<Box>(
                future: _userBoxFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      children: [
                        _buildHeaderRow(),
                        SizedBox(height: 150),
                        Expanded(
                            child: Center(child: CircularProgressIndicator())),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Column(
                      children: [
                        _buildHeaderRow(),
                        Expanded(
                            child: Center(
                                child: Text('Error: ${snapshot.error}'))),
                      ],
                    );
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return Column(
                      children: [
                        _buildHeaderRow(),
                        Expanded(
                            child: Center(
                                child: Text('No users found.',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)))),
                      ],
                    );
                  }

                  final userBox = snapshot.data!;
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getStoredUsers(userBox),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Column(
                          children: [
                            _buildHeaderRow(),
                            Expanded(
                                child:
                                    Center(child: CircularProgressIndicator())),
                          ],
                        );
                      } else if (userSnapshot.hasError) {
                        return Column(
                          children: [
                            _buildHeaderRow(),
                            Expanded(
                                child: Center(
                                    child:
                                        Text('Error: ${userSnapshot.error}'))),
                          ],
                        );
                      } else if (!userSnapshot.hasData ||
                          userSnapshot.data!.isEmpty) {
                        return Column(
                          children: [
                            _buildHeaderRow(),
                            Expanded(
                                child: Center(child: Text('No users found.'))),
                          ],
                        );
                      }

                      final users = userSnapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderRow(),
                          Expanded(
                            child: ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                final phoneNo = user['phone_no'] ?? '';
                                final isAdmin = user['isAdmin'] ?? false;

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Card(
                                    elevation: 4,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(16.0),
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${index + 1}. Phone No: $phoneNo',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isAdmin)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0),
                                                  child: Text(
                                                    'Admin',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            'Password (Hash): ${user['password'] ?? ''}',
                                            style:
                                                TextStyle(color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: IconButton(
                iconSize: 25,
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0XFF2196F3),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Admin Dashboard',
                  style: titles,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(width: 4),
          ],
        ),
        SizedBox(height: 7),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 50.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'User Lists',
                style: TextStyle(
                  color: Color(0XFFA66600),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 30,
        )
      ],
    );
  }
}
