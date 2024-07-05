import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackingPage extends StatefulWidget {
  final DocumentSnapshot drone;

  TrackingPage({required this.drone});

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  late GoogleMapController mapController;
  late StreamSubscription<DocumentSnapshot> _subscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _subscribeToLocationUpdates() {
    _subscription = FirebaseFirestore.instance
        .collection('drones')
        .doc(widget.drone.id)
        .snapshots()
        .listen((snapshot) {
      GeoPoint geoPoint = snapshot['location'];
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(geoPoint.latitude, geoPoint.longitude),
            zoom: 16.0,
          ),
        ),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
      _subscribeToLocationUpdates(); // Call _subscribeToLocationUpdates here
    });
  }

  @override
  Widget build(BuildContext context) {
    GeoPoint geoPoint = widget.drone['location'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Tracking'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Map section
          Container(
            height: 700, // Adjust the height as needed
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(0.0, 0.0), // Initial position can be anything since it will be updated
                zoom: 16.0,
              ),
              markers: Set<Marker>.of([
                Marker(
                  markerId: MarkerId(widget.drone.id),
                  position: LatLng(0.0, 0.0), // Initial position can be anything since it will be updated
                  infoWindow: InfoWindow(title: 'Drone'),
                ),
              ]),
            ),
          ),
          // Drone information section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Drone ID: ${widget.drone.id}'),
                  Text('Drone Konumu: ${geoPoint.longitude} && ${geoPoint.latitude}'),
                  Text('Drone İsmi: ${widget.drone['name']}'),
                  Text('Drone Durumu: ${widget.drone['status']}'),
                  // Add more drone information as needed
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}