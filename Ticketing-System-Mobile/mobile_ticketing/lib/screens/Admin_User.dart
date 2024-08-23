import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../Components/Reusable_background.dart';
import '../Components/Reusable_logo.dart';
import '../Constants/constants.dart';

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

  // Method to hash passwords
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // Method to get stored users from Hive
  Future<List<Map<String, dynamic>>> _getStoredUsers(Box userBox) async {
    final List<Map<String, dynamic>> users = [];

    for (var i = 0; i < userBox.length; i++) {
      final value = userBox.getAt(i) as Map<dynamic, dynamic>;
      users.add({
        'phone_no': value['phone_no'] as String,
        'password': value['password'] as String,
      });
    }

    return users;
  }

  // Method to upsert a user in Hive (update if exists, insert if not)
  Future<void> _upsertUser(Box userBox, Map<String, dynamic> user) async {
    final phoneNo = user['phone_no'];

    // Check if the user exists
    final userIndex = userBox.values.toList().indexWhere(
        (existingUser) => (existingUser as Map)['phone_no'] == phoneNo);

    if (userIndex != -1) {
      // If the user exists, update it
      await userBox.putAt(userIndex, user);
    } else {
      // If the user does not exist, add it
      await userBox.add(user);
    }
  }

  // Method to delete a user from Hive
  Future<void> _deleteUser(Box userBox, String phoneNo) async {
    final userIndex = userBox.values
        .toList()
        .indexWhere((user) => (user as Map)['phone_no'] == phoneNo);
    if (userIndex != -1) {
      await userBox.deleteAt(userIndex);
    }
  }

  // Method to show confirmation dialog before deleting a user
  Future<void> _showDeleteConfirmationDialog(
      Box userBox, String phoneNo) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this user?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await _deleteUser(userBox, phoneNo);
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User deleted')),
                );
                // Refresh the FutureBuilder to reflect the deletion
                setState(() {});
              },
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
              child: FutureBuilder<Box>(
                future: _userBoxFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return Center(child: Text('No users found.'));
                  }

                  final userBox = snapshot.data!;
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getStoredUsers(userBox),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (userSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${userSnapshot.error}'));
                      } else if (!userSnapshot.hasData ||
                          userSnapshot.data!.isEmpty) {
                        return Center(child: Text('No users found.'));
                      }

                      final users = userSnapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon:
                                    Icon(Icons.arrow_back, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pop(
                                      context); // Go back to the previous screen
                                },
                              ),
                              SizedBox(width: 8),
                              Text('Registered Users', style: titles),
                              Text('')
                            ],
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                final phoneNo = user['phone_no'];

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
                                          Text(
                                            '${index + 1}. Phone No: $phoneNo',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            'Password (Hash): ${user['password']}',
                                            style:
                                                TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          _showDeleteConfirmationDialog(
                                              userBox, phoneNo);
                                        },
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
}
