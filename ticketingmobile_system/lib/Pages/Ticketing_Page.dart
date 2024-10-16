import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../Reusable-Components/Reusable_Background.dart';
import '../Reusable-Components/Reusable_Logo.dart';
import '../Reusable-Components/Reusable_Selection.dart';
import '../Reusable-Constants/constant.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http; 


class TicketingPage extends StatefulWidget {
  @override
  State<TicketingPage> createState() => _TicketingPageState();
}

class _TicketingPageState extends State<TicketingPage> {
  int ticketCount = 1;
  final TextEditingController plateNumberController = TextEditingController();
  final TextEditingController vehicleCodeController = TextEditingController();
  final TextEditingController regionCodeController = TextEditingController();
  double? level1Price;

  bool _validateFields() {
    return plateNumberController.text.isNotEmpty &&
        vehicleCodeController.text.isNotEmpty &&
        regionCodeController.text.isNotEmpty &&
        ticketCount > 0;
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

 void _showNumberInputDialog() {
    final TextEditingController ticketCountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter ticket quantity'),
          content: TextField(
            controller: ticketCountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "Enter ticket quantity"),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('OK', style: TextStyle(fontSize: 15)),
              onPressed: () {
                final value = int.tryParse(ticketCountController.text);
                if (value != null && value > 0) {
                  setState(() {
                    ticketCount = value; 
                  });
                  Navigator.of(context).pop();
                } else {
                  _showErrorDialog(
                      'Please enter a valid ticket count greater than 0.');
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0XFF2196F3),
              ),
            ),
          ],
        );
      },
    );
  }

Future<int?> _fetchVehicleData() async {
    final String plateNumber = plateNumberController.text;
    final String regionCode = regionCodeController.text;
    final String vehicleCode = vehicleCodeController.text;

    final url = 'http://localhost:8000/api/v1/vehicles-plate-number';

    final userBox = await Hive.openBox('users');
    final List<Map> admins = userBox.values
        .where((u) => (u as Map)['isAdmin'] == true)
        .cast<Map>()
        .toList();

    if (admins.isEmpty) {
      _showErrorDialog('No admin user found.');
      return null;
    }

    final String token = admins.last['token'];

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'plate_number': plateNumber,
          'region': regionCode,
          'code': vehicleCode,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final int price = data['data']['price'];

        await _saveVehicleData(plateNumber, regionCode, vehicleCode, price);
        return price;
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      final int? localPrice =
          await _getVehiclePrice(plateNumber, regionCode, vehicleCode);
      if (localPrice != null) {
        return localPrice;
      } else {
        _showErrorDialog(
            'Failed to fetch vehicle data offline. Please check the input.');
        return null;
      }
    }
  }


  Future<void> _saveVehicleData(String plateNumber, String regionCode,
      String vehicleCode, int price) async {
    final vehicleBox = await Hive.openBox('vehicles');
    await vehicleBox.put('$plateNumber-$regionCode-$vehicleCode', price);
  }

  Future<int?> _getVehiclePrice(
      String plateNumber, String regionCode, String vehicleCode) async {
    final vehicleBox = await Hive.openBox('vehicles');
    return vehicleBox.get('$plateNumber-$regionCode-$vehicleCode');
  }


  void _showSuccessDialog(int? price) async {
    if (price == null) {
      _showErrorDialog('Unable to proceed without a valid price.');
      return;
    }

    if (!_validateFields()) {
      _showErrorDialog('Please complete all fields before selling the ticket.');
      return;
    }

    final userBox = await Hive.openBox('users');
    final List<Map> nonAdminUsers = userBox.values
        .where((user) => (user as Map)['isAdmin'] == false)
        .toList()
        .cast<Map>();

    if (nonAdminUsers.isNotEmpty) {
      final mostRecentNonAdminUser = nonAdminUsers.last;
      final phoneNumber = mostRecentNonAdminUser['phone_no'];

      final totalSales = ticketCount * price;
      final revenue = totalSales * 0.02;
      final now = DateTime.now();

      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final formattedHour = hour.toString().padLeft(2, '0');
      final formattedMinute = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final formattedTime = "$formattedHour:$formattedMinute $period";

      final reportBox = await Hive.openBox('reports');
      final report = {
        'date': formattedDate,
        'time': formattedTime,
        'ticket_count': ticketCount,
        'total_sales': totalSales,
        'revenue': revenue,
        'phone_no': phoneNumber,
        'plate_number': plateNumberController.text,
        'region_code': regionCodeController.text,
        'vehicle_code': vehicleCodeController.text,
      };

      await reportBox.add(report);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('The ticket has been sold!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetForm();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      _showErrorDialog('No non-admin user found.');
    }
  }



  void _resetForm() {
    plateNumberController.clear();
    vehicleCodeController.clear();
    regionCodeController.clear();
    setState(() {
      ticketCount = 1;
    });
  }

  void increaseTicket() {
    setState(() {
      ticketCount++;
    });
  }

  void decreaseTicket() {
    if (ticketCount > 1) {
      setState(() {
        ticketCount--;
      });
    }
  }

  @override
  void dispose() {
    plateNumberController.dispose();
    vehicleCodeController.dispose();
    regionCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ReusableBackground(),
            ReusableLogo(),
            Positioned(
              top: 60,
              left: 40,
              right: 40,
              child: Container(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          iconSize: 25,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0XFF2196F3),
                          ),
                        ),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Ticketing Page',
                              style: titles,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                      ],
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              top: 110,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 25),
                    ReusableSelection(
                      title: 'Plate Number:',
                      hintText: 'Enter Plate number',
                      isInputField: true,
                      controller: plateNumberController, onSelectionChanged: (String ) {  },
                    ),
                    SizedBox(height: 25),
                    ReusableSelection(
                      title: 'Region Code:',
                      hintText: 'Enter Region Code',
                      isInputField: true,
                      controller: regionCodeController, onSelectionChanged: (String ) {  },
                    ),
                    SizedBox(height: 25),
                    ReusableSelection(
                      title: 'Vehicle Code:',
                      hintText: 'Enter Vehicle Code',
                      isInputField: true,
                      controller: vehicleCodeController, onSelectionChanged: (String ) {  },
                    ),
                    SizedBox(height: 25),
                     Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('No. of Tickets:', style: prefix),
                          SizedBox(width: 40),
                          Expanded(
                            child: Container(
                              width: 195,
                              height: 60,
                              color: Colors.white,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Container(
                                    width: 25,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(7),
                                      color: Color(0XFF3D8BFF),
                                    ),
                                    child: GestureDetector(
                                      onTap: decreaseTicket,
                                      child: Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _showNumberInputDialog,
                                    child: Container(
                                      width: 55,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Color(0XFF0167FF), width: 2),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 5),
                                          child: Text(
                                            ticketCount.toString(),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 28,
                                                fontFamily: 'Work Sans'),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 25,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(7),
                                      color: Color(0XFF3D8BFF),
                                    ),
                                    child: GestureDetector(
                                      onTap: increaseTicket,
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                Container(
                      width: 120,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: Color(0XFF2196F3),
                      ),
                      child: TextButton(
                        onPressed: () async {
                          int? price =
                              await _fetchVehicleData(); 
                          if (price != null) {
                            _showSuccessDialog(
                                price); 
                          } else {
                            _showErrorDialog('Failed to fetch vehicle data.');
                          }
                        },
                        child: Text(
                          'Sell',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ),

                    SizedBox(height: 35),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
