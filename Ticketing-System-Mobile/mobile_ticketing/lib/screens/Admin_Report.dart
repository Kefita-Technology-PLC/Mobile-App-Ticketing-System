import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../Components/Reusable_background.dart';
import '../Components/Reusable_logo.dart';
import '../Constants/constants.dart';

class AdminReport extends StatefulWidget {
  const AdminReport({super.key});

  @override
  _AdminReportState createState() => _AdminReportState();
}

class _AdminReportState extends State<AdminReport> {
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
        return {
          'key': index,
          'association': report['association'] ?? 'Unknown Association',
          'station': report['station'] ?? 'Unknown Station',
          'date': report['date'] ?? 'Unknown Date',
          'time': report['time'] ?? 'Unknown Time',
          'total_sales': _toDouble(report['total_sales']),
          'revenue': _roundValue(_toDouble(report['total_sales']) * 0.02),
        };
      });
      _isLoading = false;
    });
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

  Future<void> _editReport(int index) async {
    final editedReport = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final report = _reportList[index];
        final stationController =
            TextEditingController(text: report['station']);
        final associationController =
            TextEditingController(text: report['association']);
        final dateController = TextEditingController(text: report['date']);
        final timeController = TextEditingController(text: report['time']);
        final salesController = TextEditingController(
            text: report['total_sales'].toStringAsFixed(2));

        return SingleChildScrollView(
          child: AlertDialog(
            title: const Text('Edit Report'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: stationController,
                  decoration: const InputDecoration(labelText: 'Station'),
                ),
                TextField(
                  controller: associationController,
                  decoration: const InputDecoration(labelText: 'Association'),
                ),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: 'Time'),
                ),
                TextField(
                  controller: salesController,
                  decoration: const InputDecoration(labelText: 'Total Sales'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final updatedReport = {
                    'station': stationController.text,
                    'association': associationController.text,
                    'date': dateController.text,
                    'time': timeController.text,
                    'total_sales': _toDouble(salesController.text),
                    'revenue':
                        _roundValue(_toDouble(salesController.text) * 0.02),
                  };
                  Navigator.pop(context, updatedReport);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (editedReport != null) {
      setState(() {
        _reportList[index] = editedReport;
        _saveReport(index, editedReport);
      });
    }
  }

  Future<void> _saveReport(int index, Map<String, dynamic> report) async {
    final reportBox = await Hive.openBox('reports');
    await reportBox.putAt(index, {
      'station': report['station'],
      'association': report['association'],
      'date': report['date'],
      'time': report['time'],
      'total_sales': report['total_sales'],
    });
  }

  Future<void> _deleteReport(int index) async {
    setState(() {
      _reportList.removeAt(index);
    });
    final reportBox = await Hive.openBox('reports');
    await reportBox.deleteAt(index);
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
            const ReusableLogo(),
            Positioned.fill(
              top: 100,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: Colors.blue,
                                      )),
                                  const Text(
                                    'Admin Dashboard',
                                    style: titles,
                                  ),
                                  const Text('')
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 40),
                                  child: Text(
                                    'Reports and Analysis',
                                    style: TextStyle(
                                      color: Color(0XFFA66600),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 70),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                    children: [
                                      Table(
                                        defaultColumnWidth:
                                            FixedColumnWidth(150),
                                        border: TableBorder.all(
                                            color: Colors.black, width: 0.5),
                                        columnWidths: {
                                          0: FixedColumnWidth(
                                              80), // Increased width for No. column
                                          7: FixedColumnWidth(180),
                                        },
                                        children: [
                                          const TableRow(
                                            decoration: BoxDecoration(
                                              color: Color(0XFF587DB4),
                                            ),
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  'No.',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  'Station',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  'Association',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  'Date',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  'Time',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  'Sale',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  'Revenue',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  'Action',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                          for (int i = 0;
                                              i < _reportList.length;
                                              i++)
                                            TableRow(
                                              decoration: BoxDecoration(
                                                color: i % 2 == 1
                                                    ? Colors.white
                                                    : Colors.grey.shade200,
                                              ),
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    '${i + 1}',
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    _reportList[i]['station'],
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    _reportList[i]
                                                        ['association'],
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    _reportList[i]['date'],
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    _reportList[i]['time'],
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    _reportList[i]
                                                            ['total_sales']
                                                        .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    _reportList[i]['revenue']
                                                        .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.edit,
                                                            color: Color(
                                                                0XFF587DB4)),
                                                        onPressed: () =>
                                                            _editReport(i),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () =>
                                                            _deleteReport(i),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          // Total Row
                                          TableRow(
                                            decoration: const BoxDecoration(
                                              color: Colors.amberAccent,
                                            ),
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  'Total',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  '',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  '',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  '',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  '',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  _reportList
                                                      .fold<double>(
                                                          0.0,
                                                          (previousValue,
                                                                  element) =>
                                                              previousValue +
                                                              element[
                                                                  'total_sales'])
                                                      .toStringAsFixed(2),
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  _reportList
                                                      .fold<double>(
                                                          0.0,
                                                          (previousValue,
                                                                  element) =>
                                                              previousValue +
                                                              element[
                                                                  'revenue'])
                                                      .toStringAsFixed(2),
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  '',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 50,
                              ),
                            ],
                          ),
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
