import 'package:flutter/material.dart';
import '../Components/Reusable_background.dart';
import '../Components/Reusable_logo.dart';
import '../Components/Reusable_selection.dart';
import '../Constants/constants.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TicketingPage extends StatefulWidget {
  @override
  State<TicketingPage> createState() => _TicketingPageState();
}

class _TicketingPageState extends State<TicketingPage> {
  int ticketCount = 1;
  String selectedDate = 'Select date';
  String selectedAssociation = 'Select Association';
  String selectedStation = 'Select station';
  String selectedType = 'Select Vehicle Type';
  String selectedTime = 'Select Time';
  bool _isLoading = false; // Declare _isLoading here
  List<String> stations = [];
  List<String> associations = [];
  @override
  void initState() {
    super.initState();
    _loadStationsAndAssociations();
  }

  void _loadStationsAndAssociations() async {
    try {
      var stationBox = await Hive.openBox('stationsBox');
      var associationBox = await Hive.openBox('associationsBox');

      setState(() {
        _isLoading = true; // Start loading state
      });

      // Fetch stations
      if (stationBox.isEmpty) {
        try {
          List<String> fetchedStations = await fetchStationsFromServer();
          print('Fetched Stations: $fetchedStations');
          if (fetchedStations.isEmpty) {
            _showErrorDialog('No stations available at the moment.');
            stations = [];
          } else {
            await storeStationsLocally(fetchedStations);
            stations = fetchedStations;
          }
        } catch (e) {
          print('Failed to fetch stations: $e');
        }
      } else {
        stations = stationBox.values.cast<String>().toList();
      }

      // Fetch associations
      if (associationBox.isEmpty) {
        try {
          List<String> fetchedAssociations =
              await fetchAssociationsFromServer();
          print('Fetched Associations: $fetchedAssociations');
          if (fetchedAssociations.isEmpty) {
            _showErrorDialog('No associations available at the moment.');
            associations = [];
          } else {
            await storeAssociationsLocally(fetchedAssociations);
            associations = fetchedAssociations;
          }
        } catch (e) {
          print('Failed to fetch associations: $e');
        }
      } else {
        associations = associationBox.values.cast<String>().toList();
      }

      setState(() {
        _isLoading = false; // End loading state
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false; // End loading state
      });
    }
  }

  Future<List<String>> fetchStationsFromServer() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8000/api/v1/stations'));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      // Extract the 'name' field from each station
      return jsonData.isNotEmpty
          ? jsonData
              .map<String>((station) => station['name'] as String)
              .toList()
          : [];
    } else if (response.statusCode == 404) {
      throw Exception('Endpoint not found');
    } else {
      print('Failed to load stations: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load stations: ${response.statusCode}');
    }
  }

  Future<void> storeStationsLocally(List<String> stations) async {
    var box = await Hive.openBox<String>('stationsBox');
    await box.clear();
    await box.addAll(stations); // More efficient way to store all stations
  }

  Future<void> storeAssociationsLocally(List<String> associations) async {
    var box = await Hive.openBox<String>('associationsBox');
    await box.clear();
    await box
        .addAll(associations); // More efficient way to store all associations
  }

  Future<List<String>> fetchAssociationsFromServer() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8000/api/v1/associations'));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      // Extract the 'name' field from each association
      return jsonData.isNotEmpty
          ? jsonData
              .map<String>((association) => association['name'] as String)
              .toList()
          : [];
    } else if (response.statusCode == 404) {
      throw Exception('Endpoint not found');
    } else {
      print('Failed to load associations: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load associations: ${response.statusCode}');
    }
  }

  void increaseTicket() {
    setState(() {
      ticketCount++;
    });
  }

  void decreaseTicket() {
    setState(() {
      if (ticketCount > 1) {
        ticketCount--;
      }
    });
  }

  void handleDateSelected(String date) {
    setState(() {
      selectedDate = date;
    });
  }

  void handleStationSelected(String station) {
    setState(() {
      selectedStation = station;
    });
  }

  void handleAssociationSelected(String association) {
    setState(() {
      selectedAssociation = association;
    });
  }

  void handleTypeSelected(String type) {
    setState(() {
      selectedType = type;
    });
  }

  void handleTimeSelected(String time) {
    setState(() {
      selectedTime = time;
    });
  }

  bool _validateFields() {
    return selectedDate != 'Select date' &&
        selectedStation != 'Select station' &&
        selectedType != 'Select Vehicle Type' &&
        selectedTime != 'Select Time' &&
        selectedAssociation != 'Select Association';
  }

  void _showSuccessDialog() async {
    if (!_validateFields()) {
      _showErrorDialog('Please complete all fields before selling the ticket.');
      return;
    }

    final totalSales = ticketCount * 5; // Calculate total sales
    final revenue = totalSales * 0.02; // 2% of total sales

    final reportBox = await Hive.openBox('reports');
    final report = {
      'station': selectedStation,
      'date': selectedDate,
      'time': selectedTime,
      'association': selectedAssociation,
      'total_sales': totalSales,
      'revenue': revenue,
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
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
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

  void _resetForm() {
    setState(() {
      ticketCount = 1;
      selectedDate = 'Select date';
      selectedStation = 'Select station';
      selectedAssociation = 'Select Association';
      selectedType = 'Select Vehicle Type';
      selectedTime = 'Select Time';
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
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
              top: 80,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Ticketing Page',
                        style: titles,
                      ),
                    ),
                    SizedBox(height: 20),
                    ReusableSelection(
                      title: 'Date:',
                      hintText: selectedDate,
                      onSelectionChanged: handleDateSelected,
                      onCustomTimePicker: () {},
                    ),
                    SizedBox(height: 25),
                    ReusableSelection(
                      title: 'Station:',
                      hintText: selectedStation,
                      onSelectionChanged: handleStationSelected,
                      options: stations.isNotEmpty ? stations : ['Loading...'],
                      onCustomTimePicker: () {},
                    ),
                    SizedBox(height: 25),
                    ReusableSelection(
                      title: 'Association:',
                      hintText: selectedAssociation,
                      onSelectionChanged: handleAssociationSelected,
                      options: associations.isNotEmpty
                          ? associations
                          : ['Loading...'],
                      onCustomTimePicker: () {},
                    ),
                    SizedBox(height: 25),
                    ReusableSelection(
                      title: 'Type:',
                      hintText: selectedType,
                      onSelectionChanged: handleTypeSelected,
                      options: ['Anbessa', 'Public', 'New'],
                      onCustomTimePicker: () {},
                    ),
                    SizedBox(height: 25),
                    ReusableSelection(
                      title: 'Time:',
                      hintText: selectedTime,
                      onSelectionChanged: handleTimeSelected,
                      options: _generateTimeOptions(),
                      onCustomTimePicker: () {},
                    ),
                    SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('No. of Tickets', style: prefix),
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
                                  Container(
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
                    SizedBox(height: 30),
                    Container(
                      width: 120,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: Color(0XFF2196F3),
                      ),
                      child: TextButton(
                        onPressed: _showSuccessDialog,
                        child: Text(
                          'Sell',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ),
                    SizedBox(height: 20), // Add bottom spacing
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _generateTimeOptions() {
    final times = <String>[];
    for (int i = 0; i < 24; i++) {
      times.add('${i.toString().padLeft(2, '0')}:00');
    }
    return times;
  }
}
