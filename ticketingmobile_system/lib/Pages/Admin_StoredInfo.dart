import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../Reusable-Components/Reusable_Background.dart';
import '../Reusable-Components/Reusable_Logo.dart';

class StoredDatas extends StatefulWidget {
  @override
  _StoredDatasState createState() => _StoredDatasState();
}

class _StoredDatasState extends State<StoredDatas> {
  List<Map<String, dynamic>> storedVehicles = [];

  @override
  void initState() {
    super.initState();
    _loadStoredVehicles();
  }

  Future<void> _loadStoredVehicles() async {
    final vehicleBox = await Hive.openBox('vehicles');
    final List<Map<String, dynamic>> vehicles = vehicleBox.keys.map((key) {
      final String combinedKey = key as String;
      final int price = vehicleBox.get(key) as int;
      final List<String> keyParts = combinedKey.split('-');
      final String plateNumber = keyParts[0];
      final String regionCode = keyParts[1];
      final String vehicleCode = keyParts[2];

      return {
        'plateNumber': plateNumber,
        'regionCode': regionCode,
        'vehicleCode': vehicleCode,
        'price': price,
      };
    }).toList();

    setState(() {
      storedVehicles = vehicles;
    });
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
              top: 100,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0XFFFF9E01),
                              ),
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
                            'Stored Datas',
                            style: TextStyle(
                              color: Color(0XFFA66600),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 250,
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: storedVehicles.isEmpty
                    ? Center(child: Text('No stored vehicles found.'))
                    : ListView.builder(
                        itemCount: storedVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = storedVehicles[index];

                          return Card(
                            elevation: 3,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                'Plate: ${vehicle['plateNumber']} | Region: ${vehicle['regionCode']}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Vehicle Code: ${vehicle['vehicleCode']}'),
                                  Text('Price: ${vehicle['price']}'),
                                ],
                              ),
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
