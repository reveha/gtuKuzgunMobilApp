import 'dart:math';

import 'package:Kuzgun/tracking_page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import 'drone_detail.dart';

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late Future<Position> _currentPosition;
  List<DocumentSnapshot> _droneList = [];
  DocumentSnapshot? _selectedDrone;

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
    double radius = 0.1;
    double maxDistance = 5.0;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('drones')
        .where('available', isEqualTo: true)
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

  void _selectDrone(DocumentSnapshot drone) {
    setState(() {
      if (_selectedDrone == drone) {
        _selectedDrone = null; // Deselect if the same drone is tapped again
      } else {
        _selectedDrone = drone; // Select the new drone
      }
    });
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
                            subtitle: Text('Latitude: ${geoPoint.latitude}, Longitude: ${geoPoint.longitude}'),
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
      floatingActionButton: _selectedDrone!= null
          ? FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          // Process the selected drone
          // For example, navigate to another page or show a confirmation dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Drone Selected'),
              content: Text('You have selected drone ID: ${_selectedDrone!.id}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Cancel
                  },
                  child: Text('Hayır'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackingPage(drone: _selectedDrone!),
                      ),
                    );
                  },
                  child: Text('Evet'),
                ),
              ],
            ),
          );
        },
      )
          : null,
    );
  }
}