// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';

import '../Reusable-Components/Reusable_Background.dart';
import '../Reusable-Components/Reusable_Logo.dart';
import '../Reusable-Constants/constant.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TicketingHistory extends StatefulWidget {
  @override
  _TicketingHistoryState createState() => _TicketingHistoryState();
}

class _TicketingHistoryState extends State<TicketingHistory> {
  List<Map<String, dynamic>> _reportList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    final reportBox = await Hive.openBox('reports');
    setState(() {
      _reportList = List.generate(reportBox.length, (index) {
        final report = reportBox.getAt(index);
        print('Report at index $index: $report');
        return {
          'key': index,
          'ticket_count': report['ticket_count'] ?? 'Unknown Ticket Number',
          'date': report['date'] ?? 'Unknown Date',
          'time': report['time'] ?? 'Unknown Time',
          'total_sales': _toDouble(report['total_sales']),
          'revenue': _roundValue(_toDouble(report['total_sales']) * 0.02),
          'phone_number': report['phone_no'] ?? 'Unknown Phone Number',
          'plate_number': report['plate_number'] ?? 'Unknown Plate Number',
          'region_code': report['region_code'] ?? 'Unknown Region Code',
          'vehicle_code': report['vehicle_code'] ?? 'Unknown Vehicle Code',
        };
      });
      _isLoading = false;
    });
  }

  Future<void> _deleteReport(int index) async {
    setState(() {
      _reportList.removeAt(index);
    });
    final reportBox = await Hive.openBox('reports');
    await reportBox.deleteAt(index);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double _roundValue(double value) {
    return (value * 100).round() / 100;
  }

  Future<void> _saveReport(int index, Map<String, dynamic> report) async {
    final reportBox = await Hive.openBox('reports');
    await reportBox.putAt(index, {
      'date': report['date'],
      'time': report['time'],
      'total_sales': report['total_sales'],
      'ticket_count': report['ticket_count'],
      'phone_number': report['phone_no'],
      'plate_number': report['plate_number'] ?? 'Unknown Plate Number',
      'region_code': report['region_code'] ?? 'Unknown Region Code',
      'vehicle_code': report['vehicle_code'] ?? 'Unknown Vehicle Code',
      'revenue': report['revenue'] ?? 'Unknown Revenue',
      'sent': false,
    });
  }

  Future<bool> sendTicketDataWithToken(BuildContext context, int index) async {
    const String url = 'http://localhost:8000/api/v1/daily-report-pos';

    try {
      final userBox = await Hive.openBox('users');
      final List<Map> admins = userBox.values
          .where((u) => (u as Map)['isAdmin'] == true)
          .cast<Map>()
          .toList();

      if (admins.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Admin user not found.'),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return false;
      }

      final String token = admins.last['token'];
      final reportBox = await Hive.openBox('reports');
      final report = reportBox.getAt(index);

      if (report != null) {
        if (report['sent'] == true) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Notice'),
                content: Text('This report has already been sent!'),
                actions: [
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          return false;
        }

        Map<String, dynamic> ticketData = {
          'ticket_count': report['ticket_count'],
          'total_sale': report['total_sales'],
          'revenue': report['revenue'],
        };

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(ticketData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          report['sent'] = true;
          await reportBox.putAt(index, report);

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Success'),
                content: Text('Data sent successfully!'),
                actions: [
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );

          return true;
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Error'),
                content: Text(
                    'Failed to send data. Status code: ${response.statusCode}'),
                actions: [
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );

          return false;
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('No report found at index $index'),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return false;
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred: $e'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return false;
    }
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
              top: 70,
              left: 0,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: IconButton(
                              iconSize: 25,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(
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
                              'Ticketing History',
                              style: titles,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              top: 140,
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  for (var entry in groupBy(_reportList,
                                      (report) => report['date']).entries)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Date: ${entry.key}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0XFF587DB4),
                                            ),
                                          ),
                                        ),
                                        Table(
                                          defaultColumnWidth:
                                              const FixedColumnWidth(150),
                                          border: TableBorder.all(
                                              color: Colors.black, width: 0.5),
                                          columnWidths: const {
                                            0: FixedColumnWidth(80), // No.
                                            1: FixedColumnWidth(
                                                150), // Phone No.
                                            2: FixedColumnWidth(150), // Station
                                            3: FixedColumnWidth(
                                                150), // Association
                                            4: FixedColumnWidth(
                                                150), // Ticket-Count
                                            5: FixedColumnWidth(150), // Time
                                            6: FixedColumnWidth(
                                                150), // Deployment
                                            7: FixedColumnWidth(150), // Sale
                                            8: FixedColumnWidth(150), // Revenue
                                          },
                                          children: [
                                            TableRow(
                                              decoration: const BoxDecoration(
                                                  color: Color(0XFF587DB4)),
                                              children: List.generate(
                                                9,
                                                (index) => Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    [
                                                      'No.',
                                                      'Phone No',
                                                      'Time',
                                                      'Plate-Number',
                                                      'Region-Code',
                                                      'Vehicle-Code',
                                                      'Ticket-Count',
                                                      'Sale',
                                                      'Revenue'
                                                    ][index],
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            for (int i = 0;
                                                i < entry.value.length;
                                                i++)
                                              TableRow(
                                                decoration: BoxDecoration(
                                                  color: i % 2 == 1
                                                      ? Colors.white
                                                      : Colors.grey.shade200,
                                                ),
                                                children:
                                                    List.generate(9, (index) {
                                                  final report = entry.value[i];
                                                  switch (index) {
                                                    case 0:
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                          '${i + 1}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                                    case 1:
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                          report['phone_number'] ??
                                                              'N/A',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                                    case 2:
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                          report['time'] ??
                                                              'N/A',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                                    case 3:
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                          report['plate_number'] ??
                                                              '',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                                    case 4:
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                          report['region_code'] ??
                                                              'N/A',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                                    case 5:
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                          report['vehicle_code'] ??
                                                              '',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                                    case 6:
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                          report['ticket_count']
                                                                  ?.toString() ??
                                                              '0',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                                    case 7:
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                          report['total_sales']
                                                                  ?.toString() ??
                                                              '0.00',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                                    case 8:
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                          report['revenue']
                                                                  ?.toString() ??
                                                              '0.00',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                                    default:
                                                      return Container();
                                                  }
                                                }),
                                              ),
                                            // Total Row
                                            TableRow(
                                              decoration: const BoxDecoration(
                                                  color: Color(0XFF587DB4)),
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text(
                                                    'Total',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Text('')),
                                                const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Text('')),
                                                const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Text('')),
                                                const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Text('')),
                                                const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Text('')),
                                                const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Text('')),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    entry.value
                                                        .fold<double>(
                                                          0.0,
                                                          (previousValue,
                                                                  element) =>
                                                              previousValue +
                                                              element[
                                                                  'total_sales'],
                                                        )
                                                        .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    entry.value
                                                        .fold<double>(
                                                          0.0,
                                                          (previousValue,
                                                                  element) =>
                                                              previousValue +
                                                              element[
                                                                  'revenue'],
                                                        )
                                                        .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
