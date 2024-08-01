import 'dart:math';

import 'package:Kuzgun/tracking_page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late Future<Position> _currentPosition;
  List<DocumentSnapshot> _droneList = [];
  DocumentSnapshot? _selectedDrone;
  String? _selectedCarPlate;
  List<String> _carPlates = [];
  bool _loadingCarPlates = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _getCurrentLocation();
    fetchNearbyDrones();
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  Future<Position> _getCurrentLocation() async {
    setState(() {
      _currentPosition = Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    });
    return _currentPosition;
  }

  Future<void> fetchNearbyDrones() async {
    Position position = await _getCurrentLocation();

    double lat = position.latitude;
    double lng = position.longitude;
    double maxDistance = 20.0;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('drones')
        .where('available', isEqualTo: true)
        .where('status', isEqualTo: 'base')
        .get();

    List<DocumentSnapshot> nearbyDrones = [];

    snapshot.docs.forEach((doc) {
      GeoPoint geoPoint = doc['location'];
      double distance = _calculateDistance(lat, lng, geoPoint.latitude, geoPoint.longitude);
      if (distance <= maxDistance) {
        nearbyDrones.add(doc);
      }
    });

    setState(() {
      _droneList = nearbyDrones;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double latRad1 = _toRadians(lat1);
    double latRad2 = _toRadians(lat2);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(latRad1) * cos(latRad2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = R * c;

    return distance;
  }

  double _toRadians(double deg) {
    return deg * pi / 180;
  }

  String _calculateArrivalTime(double distance) {
    const double speedKmH = 20.0; // Drone speed in km/h
    double timeHours = distance / speedKmH; // Time in hours
    int minutes = (timeHours * 60).round(); // Convert hours to minutes
    return '$minutes dakika';
  }

  void _selectDrone(DocumentSnapshot drone) {
    setState(() {
      if (_selectedDrone == drone) {
        _selectedDrone = null; // Deselect if the same drone is tapped again
      } else {
        _selectedDrone = drone; // Select the new drone
      }
    });
  }

  void _processOrder() async {
    if (_selectedDrone != null) {
      await _fetchCarPlates(); // Fetch car plates before showing the confirmation dialog

      showDialog(
        context: context,
        builder: (BuildContext context) {
          String? _selectedCarPlate = _carPlates.isNotEmpty ? _carPlates[0] : null;

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: Text('Sipariş Onayı'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Drone ID: ${_selectedDrone!.id} siparişini onaylıyor musunuz?'),
                    if (_loadingCarPlates)
                      CircularProgressIndicator()
                    else
                      DropdownButton<String>(
                        value: _selectedCarPlate,
                        hint: Text('Lütfen Araç Seçiniz'),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCarPlate = newValue;
                          });
                        },
                        items: _carPlates.map<DropdownMenuItem<String>>((String plate) {
                          return DropdownMenuItem<String>(
                            value: plate,
                            child: Text(plate),
                          );
                        }).toList(),
                      ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('İptal'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Onayla'),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      if (_selectedCarPlate != null) {
                        await _processOrderWithCarPlate(_selectedCarPlate!);
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }
  Future<void> _fetchCarPlates() async {
    setState(() {
      _loadingCarPlates = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userEmail = user.email ?? '';

        // Query the users collection for the document where email matches the authenticated user's email
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userSnapshot.docs.first;

          List<dynamic> carPlates = userDoc['cars'] ?? [];
          setState(() {
            _carPlates = carPlates.map((plate) => plate.toString()).toList();
            _selectedCarPlate = _carPlates.isNotEmpty ? _carPlates[0] : null;
          });
        }
      }
    } catch (e) {
      print('Error fetching car plates: $e');
      // TODO: Handle error (e.g., show an error message to the user)
    } finally {
      setState(() {
        _loadingCarPlates = false;
      });
    }
  }

  Future<void> _processOrderWithCarPlate(String carPlate) async {
    if (_selectedDrone != null) {
      // Update drone availability
      await FirebaseFirestore.instance
          .collection('drones')
          .doc(_selectedDrone!.id)
          .update({'available': false});

      // Add new order to 'orders' collection
      await FirebaseFirestore.instance.collection('orders').add({
        'droneName': _selectedDrone!['name'],
        'droneId': _selectedDrone!.id,
        'location': _selectedDrone!['location'],
        'status': 'Approved',
        'carPlate': carPlate, // Include the selected car plate
      });

      // Navigate to the tracking page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrackingPage(drone: _selectedDrone!),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('En Yakın İstasyonlar'),
        backgroundColor: Colors.indigo,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<Position>(
        future: _currentPosition,
        builder: (context, AsyncSnapshot<Position> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Konum alınamadı.'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Konum bilgisi bulunamadı.'));
          } else {
            Position position = snapshot.data!;
            return Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center, // Align the image to the center
                    child: FractionallySizedBox(
                      widthFactor: 0.5, // Adjust these factors to scale the image size
                      heightFactor: 0.5,
                      child: Opacity(
                        opacity: 0.1,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain, // Use 'contain' to maintain aspect ratio
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16.0,
                  left: 16.0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  top: 80.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                  child: ListView.builder(
                    itemCount: _droneList.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot drone = _droneList[index];
                      GeoPoint geoPoint = drone['location'];
                      bool isSelected = _selectedDrone == drone;
                      double distance = _calculateDistance(
                        position.latitude,
                        position.longitude,
                        geoPoint.latitude,
                        geoPoint.longitude,
                      );
                      String arrivalTime = _calculateArrivalTime(distance);
                      return GestureDetector(
                        onTap: () {
                          _selectDrone(drone);
                        },
                        child: Card(
                          color: isSelected ? Colors.lightBlueAccent : Colors.white,
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.airplane_ticket),
                            title: Text('Drone ID: ${drone.id}'),
                            subtitle: Text(
                              'Latitude: ${geoPoint.latitude}, Longitude: ${geoPoint.longitude}\n'
                                  'Tahmini varış süresi: $arrivalTime',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: _selectedDrone != null
          ? FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          _processOrder();
        },
      )
          : null,
    );
  }
}
